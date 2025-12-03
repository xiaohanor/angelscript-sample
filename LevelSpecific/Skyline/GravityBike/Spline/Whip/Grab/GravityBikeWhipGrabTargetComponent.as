event void FGravityBikeWhipOnGrabbed(UGravityBikeWhipComponent WhipComp, UGravityBikeWhipGrabTargetComponent GrabTarget);
event void FGravityBikeWhipOnDropped(UGravityBikeWhipComponent WhipComp, UGravityBikeWhipGrabTargetComponent GrabTarget, EGravityBikeWhipGrabState GrabState, UGravityBikeWhipThrowTargetComponent ThrowAtTarget);
event void FGravityBikeWhipTargetOnDestroyed(UGravityBikeWhipGrabTargetComponent GrabTarget);
delegate bool FGravityBikeWhipGrabTargetCondition();
delegate UGravityBikeWhipThrowTargetComponent  FGravityBikeWhipEnemyTarget();

enum EGravityBikeWhipGrabState
{
	None,
	Grabbed,
	Thrown,
	Dropped
}

struct FGravityBikeWhipGrabTargetConditionData
{
	FInstigator Instigator;
	FGravityBikeWhipGrabTargetCondition Condition;
};

struct FGravityBikeWhipThrowHitData
{
	AActor HitActor;
	FVector ImpactPoint;
	FVector ImpactNormal;
};

UCLASS(NotBlueprintable, HideCategories = "Activation Cooking Tags AssetUserData Navigation ComponentTick Disable Rendering LOD")
class UGravityBikeWhipGrabTargetComponent : UTargetableComponent
{
	default TargetableCategory = GravityBikeWhip::TargetableCategoryGrab;
	default UsableByPlayers = EHazeSelectPlayer::Zoe;

	UPROPERTY(EditDefaultsOnly, Category = "Whip Grab Target Component")
	int MaxMultiGrabCount = 3;

	UPROPERTY(EditDefaultsOnly, Category = "Whip Grab Target Component")
	EGravityBikeWhipGrabCategory GrabCategory;

	/**
	 * How far away we want the reference point to be when this object is held.
	 */
	UPROPERTY(EditAnywhere, Category = "Whip Grab Target Component|Offset", Meta = (UIMin = "0.0", UIMax = "1.0"))
	float OffsetMultiplier = 1;

	UPROPERTY(EditDefaultsOnly, Category = "Whip Grab Target Component|Scale")
	float GrabScale = 1;

	UPROPERTY(EditDefaultsOnly, Category = "Whip Grab Target Component|Scale")
	float GrabScaleDownSpeed = 5;

	UPROPERTY(EditDefaultsOnly, Category = "Whip Grab Target Component|Scale")
	float GrabScaleUpSpeed = 1;

	UPROPERTY(EditDefaultsOnly, Category = "Whip Grab Target Component|Force Feedback")
	UForceFeedbackEffect GrabForceFeedbackOverride = nullptr;

	UPROPERTY(EditDefaultsOnly, Category = "Whip Grab Target Component|Force Feedback")
	UForceFeedbackEffect ThrowForceFeedbackOverride = nullptr;

	UPROPERTY(Category = "Whip Grab Target Component")
	FGravityBikeWhipOnGrabbed OnGrabbed;

	UPROPERTY(Category = "Whip Grab Target Component")
	FGravityBikeWhipOnDropped OnDropped;

	FGravityBikeWhipTargetOnDestroyed OnDestroyed;

	UPROPERTY(EditAnywhere, Category = "Audio")
	FGravityWhipTargetAudioData AudioData;

	// Grab
	UPROPERTY(NotEditable, BlueprintReadOnly)
	EGravityBikeWhipGrabState GrabState;
	FGravityBikeWhipGrabMoveData GrabMoveData;
	private UGravityBikeWhipComponent GrabbedBy_Internal;
	private TArray<FGravityBikeWhipGrabTargetConditionData> TargetConditions;

	// Scale
	private FVector InitialScale;

	// Throw
	private UGravityBikeWhipThrowTargetComponent ThrowTarget;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		Super::BeginPlay();

		InitialScale = Owner.ActorScale3D;
		
		// Disable camera collision
		TArray<UPrimitiveComponent> Primitives;
		Owner.GetComponentsByClass(UPrimitiveComponent, Primitives);
		for(auto Primitive : Primitives)
		{
			Primitive.SetCollisionResponseToChannel(ECollisionChannel::ECC_Camera, ECollisionResponse::ECR_Ignore);
		}

		// Don't tick before being grabbed
		AddComponentTickBlocker(this);
	}

	UFUNCTION(BlueprintOverride)
	void EndPlay(EEndPlayReason EndPlayReason)
	{
		Super::EndPlay(EndPlayReason);

		OnDestroyed.Broadcast(this);
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		FVector Scale = Owner.ActorScale3D;
		if(GrabState == EGravityBikeWhipGrabState::Grabbed)
		{
			switch(GrabbedBy_Internal.GetWhipState())
			{
				case EGravityBikeWhipState::Pull:
				case EGravityBikeWhipState::Lasso:
					Scale = Math::VInterpConstantTo(Scale, InitialScale * GrabScale, DeltaSeconds, GrabScaleDownSpeed);
					break;

				default:
					Scale = Math::VInterpConstantTo(Scale, InitialScale, DeltaSeconds, GrabScaleUpSpeed);
			}
		}
		else
		{
			Scale = Math::VInterpConstantTo(Scale, InitialScale, DeltaSeconds, GrabScaleUpSpeed);
		}

		Owner.SetActorScale3D(Scale);
	}

	void AddTargetCondition(FInstigator Instigator, FGravityBikeWhipGrabTargetCondition TargetCondition)
	{
		for (FGravityBikeWhipGrabTargetConditionData& ExistingTargetCondition : TargetConditions)
		{
			if (ExistingTargetCondition.Instigator == Instigator)
			{
				ExistingTargetCondition.Condition = TargetCondition;
				return;
			}
		}

		FGravityBikeWhipGrabTargetConditionData TargetConditionData;
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
#if EDITOR
		if(GetGravityBikeWhipGrabCategoryPriority(GrabCategory) == 0)
			PrintWarning(f"No Priority on {Owner.Name} with category {GrabCategory}!", 0);
#endif

		Targetable::ApplyVisibleRange(Query, GravityBikeWhip::TargetVisibleRange);
		Targetable::ApplyTargetableRange(Query, GravityBikeWhip::TargetTargetableRange);
		Targetable::ApplyDistanceToScore(Query);

		if(!Query.Result.bPossibleTarget)
			return false;

		if(!Query.Result.bVisible)
			return false;

		if(Query.Result.Score < 0)
			return false;

		switch(GrabState)
		{
			case EGravityBikeWhipGrabState::None:
				break;

			case EGravityBikeWhipGrabState::Grabbed:
				return false;

			case EGravityBikeWhipGrabState::Thrown:
				return false;

			case EGravityBikeWhipGrabState::Dropped:
				return false;
		}

		auto WhipComp = UGravityBikeWhipComponent::Get(Query.Player);
		if(WhipComp == nullptr)
			return false;

		FVector2D TargetScreenUV;
		bool bAimOnScreen = SceneView::ProjectWorldToViewpointRelativePosition(
			GravityBikeSpline::GetDriverPlayer(), WorldLocation, TargetScreenUV
		);

		if (!bAimOnScreen || !IsScreenUVVisible(TargetScreenUV))
			return false;

		for(auto& TargetConditionData : TargetConditions)
		{
			if(TargetConditionData.Condition.IsBound())
			{
				if(!TargetConditionData.Condition.Execute())
					return false;
			}
		}

		Query.Result.Score += GetGravityBikeWhipGrabCategoryPriority(GrabCategory);

		AddScoreFromInput(Query);

		return true;
	}

	private void AddScoreFromInput(FTargetableQuery& Query) const
	{
		if(Query.Result.Score < 0)
			return;

		auto FullscreenPlayer = SceneView::IsFullScreen() ? SceneView::GetFullScreenPlayer() : Query.Player;

		FVector2D TargetScreenUV;
		bool bAimOnScreen = SceneView::ProjectWorldToViewpointRelativePosition(
			FullscreenPlayer, WorldLocation, TargetScreenUV
		);

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

		Query.Result.Score += ScoreFromAngle;
	}

	bool IsScreenUVVisible(FVector2D ScreenUV) const
	{
		if(ScreenUV.X > 1 || ScreenUV.X < 0)
			return false;

		if(ScreenUV.Y > 1 || ScreenUV.Y < 0)
			return false;

		return true;
	}

	void Grabbed(UGravityBikeWhipComponent WhipComp)
	{
		check(!IsGrabbed());
		check(IsValid(WhipComp));

		GrabbedBy_Internal = WhipComp;

		GrabState = EGravityBikeWhipGrabState::Grabbed;

		GrabMoveData = FGravityBikeWhipGrabMoveData(WhipComp, Owner.ActorLocation, Owner.ActorVelocity);

		OnGrabbed.Broadcast(WhipComp, this);

		TArray<UPrimitiveComponent> Primitives;
		Owner.GetComponentsByClass(UPrimitiveComponent, Primitives);
		for(auto Primitive : Primitives)
		{
			Primitive.SetCollisionResponseToChannel(ECollisionChannel::PlayerAiming, ECollisionResponse::ECR_Ignore);
		}

		// Start ticking since we want to modify scale
		RemoveComponentTickBlocker(this);
	}

	void Dropped(UGravityBikeWhipComponent WhipComp, EGravityBikeWhipGrabState InGrabState, UGravityBikeWhipThrowTargetComponent InThrowTarget)
	{
		check(IsGrabbed());
		check(GrabbedBy_Internal == WhipComp);
		
		GrabState = InGrabState;
		ThrowTarget = InThrowTarget;
		OnDropped.Broadcast(WhipComp, this, GrabState, ThrowTarget);

		TArray<UPrimitiveComponent> Primitives;
		Owner.GetComponentsByClass(UPrimitiveComponent, Primitives);
		for(auto Primitive : Primitives)
		{
			Primitive.SetCollisionResponseToChannel(ECollisionChannel::PlayerAiming, ECollisionResponse::ECR_Block);
		}
	}

	UFUNCTION(BlueprintPure)
	bool IsGrabbed() const
	{
		if(GrabState == EGravityBikeWhipGrabState::Grabbed)
			return true;

		return false;
	}

	bool IsGrabbedOrThrown() const
	{
		if(GrabState != EGravityBikeWhipGrabState::None)
			return true;

		return false;
	}

	UFUNCTION(BlueprintPure)
	UGravityBikeWhipComponent GetWhipComponent() const
	{
		return GrabbedBy_Internal;
	}

	bool HasThrowTarget() const
	{
		if(IsGrabbed())
		{
			UGravityBikeWhipThrowTargetComponent Target = GetWhipComponent().GetThrowTarget();
			if(!IsValid(Target))
				return false;

			auto TargetHealthComp = UGravityBikeSplineEnemyHealthComponent::Get(Target.Owner);
			if(TargetHealthComp != nullptr && TargetHealthComp.IsDead())
				return false;

			return true;
		}
		else
		{
			if(!IsValid(ThrowTarget))
				return false;

			auto TargetHealthComp = UGravityBikeSplineEnemyHealthComponent::Get(ThrowTarget.Owner);
			if(TargetHealthComp != nullptr && TargetHealthComp.IsDead())
				return false;

			return true;
		}
	}

	FVector GetThrowTargetWorldLocation() const
	{
		check(HasThrowTarget());
		return GetThrowTarget().WorldLocation;
	}

	FVector GetThrowTargetVelocity() const
	{
		check(HasThrowTarget());
		return GetThrowTarget().Owner.ActorVelocity;
	}

	UGravityBikeWhipThrowTargetComponent GetThrowTarget() const
	{
		check(HasThrowTarget());
		if(IsGrabbed())
			return GetWhipComponent().GetThrowTarget();
		else
			return ThrowTarget;
	}

	void Reset()
	{
		GrabState = EGravityBikeWhipGrabState::None;
		GrabMoveData = FGravityBikeWhipGrabMoveData();
		TargetConditions.Empty();
		GrabbedBy_Internal = nullptr;
		Owner.SetActorScale3D(InitialScale);
		ThrowTarget = nullptr;

		AddComponentTickBlocker(this);
	}
}