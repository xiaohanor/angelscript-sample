delegate bool FGravityBikeWhipThrowTargetCondition();

struct FGravityBikeWhipThrowTargetConditionData
{
	FInstigator Instigator;
	FGravityBikeWhipThrowTargetCondition Condition;
};

UCLASS(NotBlueprintable, HideCategories = "Activation Cooking Tags AssetUserData Navigation ComponentTick Disable Rendering LOD")
class UGravityBikeWhipThrowTargetComponent : UTargetableComponent
{
	default TargetableCategory = GravityBikeWhip::TargetableCategoryThrow;
	default UsableByPlayers = EHazeSelectPlayer::Zoe;

	private UGravityBikeWhipGrabTargetComponent GrabTargetComp;
	private UGravityBikeSplineEnemyHealthComponent EnemyHealthComp;
	private TArray<FGravityBikeWhipThrowTargetConditionData> TargetConditions;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		Super::BeginPlay();
		
		GrabTargetComp = UGravityBikeWhipGrabTargetComponent::Get(Owner);
		EnemyHealthComp = UGravityBikeSplineEnemyHealthComponent::Get(Owner);
	}

	void AddTargetCondition(FInstigator Instigator, FGravityBikeWhipThrowTargetCondition TargetCondition)
	{
		for (FGravityBikeWhipThrowTargetConditionData& ExistingTargetCondition : TargetConditions)
		{
			if (ExistingTargetCondition.Instigator == Instigator)
			{
				ExistingTargetCondition.Condition = TargetCondition;
				return;
			}
		}

		FGravityBikeWhipThrowTargetConditionData TargetConditionData;
		TargetConditionData.Instigator = Instigator;
		TargetConditionData.Condition = TargetCondition;

		TargetConditions.Add(TargetConditionData);
	}

	void RemoveTargetCondition(FInstigator Instigator)
	{
		for (int i = TargetConditions.Num() - 1; i >= 0; --i)
		{
			if (TargetConditions[i].Instigator == Instigator)
			{
				TargetConditions.RemoveAt(i);
				break;
			}
		}
	}

	bool CheckTargetable(FTargetableQuery& Query) const override
	{
		if(IsValid(GrabTargetComp) && GrabTargetComp.IsGrabbedOrThrown())
			return false;

		if(IsValid(EnemyHealthComp) && EnemyHealthComp.IsDead())
			return false;

		auto FullscreenPlayer = SceneView::IsFullScreen() ? SceneView::GetFullScreenPlayer() : Query.Player;

		Targetable::ApplyVisibleRange(Query, GravityBikeWhip::TargetVisibleRange);
		//Targetable::ApplyTargetableRange(Query, GravityBikeWhip::TargetTargetableRange);

		if(!Query.Result.bPossibleTarget)
			return false;

		FVector2D TargetScreenUV;
		const bool bAimOnScreen = SceneView::ProjectWorldToViewpointRelativePosition(
			FullscreenPlayer,
			WorldLocation,
			TargetScreenUV
		);

		if (!bAimOnScreen || !IsScreenUVVisible(TargetScreenUV))
			return false;

#if !RELEASE
		if(GravityBikeWhip::AutoTarget.IsEnabled())
		{
			// All targets are valid, no need to aim!
			Query.Result.Score = (TargetScreenUV - FVector2D(0.5, 0.5)).Size();
			return true;
		}
#endif

		FVector AimRayScreenOrigin;
		FVector DummyOutDirection;

		{
			FVector2D AimRayOriginUV;
			SceneView::ProjectWorldToViewpointRelativePosition(
				FullscreenPlayer,
				Query.AimRay.Origin,
				AimRayOriginUV
			);

			SceneView::DeprojectScreenToWorld_Relative(
				FullscreenPlayer,
				AimRayOriginUV,
				AimRayScreenOrigin,
				DummyOutDirection
			);
		}

		FVector ScreenSpaceDirection = Query.AimRay.Direction.VectorPlaneProject(Query.ViewForwardVector).GetSafeNormal();

		//Debug::DrawDebugDirectionArrow(AimRayScreenOrigin, ScreenSpaceDirection, 5, 1, FLinearColor::DPink, 0.2);

		FVector TargetScreenOrigin;
		SceneView::DeprojectScreenToWorld_Relative(
			GravityBikeSpline::GetDriverPlayer(),
			TargetScreenUV,
			TargetScreenOrigin,
			DummyOutDirection
		);

		const FVector ToTarget = TargetScreenOrigin - AimRayScreenOrigin;

		const float Angle = ToTarget.GetAngleDegreesTo(ScreenSpaceDirection);
		const float AngleAlpha = Math::GetPercentageBetweenClamped(0, 90, Angle);

		float ScoreFromAngle = 1.0 - AngleAlpha;
		ScoreFromAngle = Math::Pow(ScoreFromAngle, 2);
		//Debug::DrawDebugString(WorldLocation, f"ScoreFromAngle: {ScoreFromAngle}");

		const float DistanceFromPlayer = ToTarget.Size();
		const float DistanceFromAlpha = Math::GetPercentageBetweenClamped(0, 20, DistanceFromPlayer);

		float ScoreFromDistance = 1.0 - DistanceFromAlpha;
		ScoreFromDistance = Math::Pow(ScoreFromDistance, 2);

		Query.Result.Score = ScoreFromAngle + ScoreFromDistance;

		if(!Query.Result.bPossibleTarget)
			return false;

		for(auto& TargetConditionData : TargetConditions)
		{
			if(TargetConditionData.Condition.IsBound())
			{
				if(!TargetConditionData.Condition.Execute())
					return false;
			}
		}

		TArray<UPrimitiveComponent> IgnoredComponents;
		if (!Targetable::RequireAimToPointNotOccluded(Query, WorldLocation, IgnoredComponents))
			return false;

		const auto WhipComp = UGravityBikeWhipComponent::Get(Query.Player);
		if(WhipComp != nullptr && WhipComp.HasThrowTarget() && WhipComp.GetThrowTarget() == this)
		{
			Query.Result.Score *= GravityBikeWhip::TargetIsMainMultiplier;
		}

		return true;
	}

	bool IsScreenUVVisible(FVector2D ScreenUV) const
	{
		if(ScreenUV.X > 1 || ScreenUV.X < 0)
			return false;

		if(ScreenUV.Y > 1 || ScreenUV.Y < 0)
			return false;

		return true;
	}

#if EDITOR
	FVector DebugScreenToWorldLocation(FVector2D ScreenUV) const
	{
		FVector Location = FVector::ZeroVector;
		FVector Direction = FVector::ZeroVector;
		SceneView::DeprojectScreenToWorld_Relative(GravityBikeSpline::GetDriverPlayer(), ScreenUV, Location, Direction);
		return Location + Direction * 100;
	}

	void DrawScreenSpaceBox(FVector2D ScreenUV, FVector2D Extent, FLinearColor Color) const
	{
		const FVector Location = DebugScreenToWorldLocation(ScreenUV);
		Debug::DrawDebugBox(Location, FVector(0, Extent.X * GravityBikeWhip::AimBoxScale, Extent.Y * GravityBikeWhip::AimBoxScale), GravityBikeSpline::GetDriverPlayer().ViewRotation, Color, 1);
	}

	void DrawScreenSpaceLine(FVector2D StartUV, FVector2D EndUV, FLinearColor Color) const
	{
		const FVector WorldStart = DebugScreenToWorldLocation(StartUV);
		const FVector WorldEnd = DebugScreenToWorldLocation(EndUV);
		Debug::DrawDebugLine(WorldStart, WorldEnd, Color, 1);
	}

	void DrawScreenSpaceString(FVector2D ScreenUV, FString String, FLinearColor Color) const
	{
		const FVector Location = DebugScreenToWorldLocation(ScreenUV);
		Debug::DrawDebugString(Location, String, Color, 0,2);
	}
#endif
};