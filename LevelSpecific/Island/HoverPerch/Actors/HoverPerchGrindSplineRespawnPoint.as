enum EHoverPerchGrindSplineRespawnHeading
{
	Forward,
	Backward
}

UCLASS(Abstract)
class AHoverPerchGrindSplineRespawnPoint : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	USceneComponent SpawnRoot;

	UPROPERTY(EditAnywhere)
	EHoverPerchGrindSplineRespawnHeading MioHeading;

	UPROPERTY(EditAnywhere)
	EHoverPerchGrindSplineRespawnHeading ZoeHeading;

	UPROPERTY(BlueprintHidden, NotVisible)
	TSoftObjectPtr<AHoverPerchGrindSpline> GrindSpline;

#if EDITOR
	UPROPERTY(DefaultComponent, Attach = Root)
	UEditorBillboardComponent Billboard;
	default Billboard.SpriteName = "S_Player";

	UPROPERTY(BlueprintHidden, NotVisible)
	FTransform EditorGrindTransform;

	UFUNCTION(CallInEditor)
	void SnapIconAboveSpawnRoot()
	{
		ActorLocation = SpawnRoot.WorldLocation + FVector::UpVector * 300.0;
		Editor::SelectActor(this);
	}

	UFUNCTION(BlueprintOverride)
	void OnActorModifiedInEditor()
	{
		FTransform ClosestTransform;
		float ClosestDistance = MAX_flt;
		AHoverPerchGrindSpline ClosestGrindSpline;

		TListedActors<AHoverPerchGrindSpline> ListedGrinds;
		if(ListedGrinds.Num() == 0)
			return;

		for(AHoverPerchGrindSpline Grind : ListedGrinds)
		{
			UHazeSplineComponent Spline = Spline::GetGameplaySpline(Grind);
			FTransform WorldTransform = Spline.GetClosestSplineWorldTransformToWorldLocation(ActorLocation);
			float Distance = WorldTransform.Location.Distance(ActorLocation);
			if(Distance < ClosestDistance)
			{
				ClosestDistance = Distance;
				ClosestTransform = WorldTransform;
				ClosestGrindSpline = Grind;
			}
		}

		float Offset = Cast<UHoverPerchGrindSplineCapability>(UHoverPerchGrindSplineCapability.DefaultObject).UpwardsOffset;
		SpawnRoot.WorldLocation = ClosestTransform.Location + FVector::UpVector * Offset;
		GrindSpline = ClosestGrindSpline;
		EditorGrindTransform = ClosestTransform;
	}

	UFUNCTION(BlueprintOverride)
	void OnVisualizeInEditor() const
	{
		if(GrindSpline == nullptr)
			return;

		FVector Direction = EditorGrindTransform.Rotation.ForwardVector;
		FVector MioDirection = MioHeading == EHoverPerchGrindSplineRespawnHeading::Forward ? Direction : -Direction;
		FVector ZoeDirection = ZoeHeading == EHoverPerchGrindSplineRespawnHeading::Forward ? Direction : -Direction;

		bool bMioZoeSameDirection = MioHeading == ZoeHeading;

		const FVector ArrowOrigin = SpawnRoot.WorldLocation + FVector::UpVector * 100.0;
		const float Length = 100.0;
		const float ArrowSize = 15.0;
		const float Thickness = 5.0;

		Debug::DrawDebugDirectionArrow(ArrowOrigin, MioDirection, Length, ArrowSize, bMioZoeSameDirection ? FLinearColor::Purple : FLinearColor::Red, Thickness);

		if(bMioZoeSameDirection)
			return;

		Debug::DrawDebugDirectionArrow(ArrowOrigin, ZoeDirection, Length, ArrowSize, FLinearColor::LucBlue, Thickness);
	}
#endif

	void TeleportHoverPerchToRespawnPoint(AHoverPerchActor HoverPerch)
	{
		EHoverPerchGrindSplineRespawnHeading Heading = HoverPerch.PlayerLocker == nullptr || HoverPerch.PlayerLocker.IsMio() ? MioHeading : ZoeHeading;
		HoverPerch.ForcedGrind = GrindSpline.Get();
		HoverPerch.bForcedGrindBackward = Heading == EHoverPerchGrindSplineRespawnHeading::Backward;
		HoverPerch.TeleportActor(SpawnRoot.WorldLocation, SpawnRoot.WorldRotation, this);
	}
}

UFUNCTION()
mixin void TeleportToGrindRespawnPoint(AHoverPerchActor HoverPerch, AHoverPerchGrindSplineRespawnPoint RespawnPoint)
{
	RespawnPoint.TeleportHoverPerchToRespawnPoint(HoverPerch);
}