class USanctuaryBossMedallion2DPlaneMovementCapability : UHazeCapability
{
	default CapabilityTags.Add(MedallionTags::MedallionTag);
	default CapabilityTags.Add(CapabilityTags::Movement);
	default TickGroup = EHazeTickGroup::BeforeMovement;
	// This is 30 because it has to be before other boss capabilities with BeforeMovement but still after DoubleInteractionCapability that is at TickGroupOrder 29
	// because that starts the boss capabilities.
	default TickGroupOrder = 30;

	ASanctuaryBossMedallion2DPlane Plane;

	FHazeAcceleratedTransform AccTransform;

	FHazeAcceleratedFloat AccAdditionalOffset;
	float TargetOffsetToTrain = 0.0;
	float RandomOffsetDuration = 0.0;
	float RandomOffsetTimer = 0.0;

	const float OutOfImageOffset = -60000.0;
	const float InsideImageOffset = -9000.0;

	float MoveTypeLerpDuration = 0.0;
	bool bLerpDone = true;
	float TimeOfSwitchState = -100.0;

	TOptional<float> TargetDistBetweenCameraSplineAndPlaneSpline;
	float BaseCameraSplineRadius;

	UMedallionPlayerComponent MioMedallionComp;
	ASanctuaryBossMedallionSpline FlyingSpline;
	UMedallionPlayerReferencesComponent MioRefs;

	AHazePlayerCharacter Mio;
	AHazePlayerCharacter Zoe;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Plane = Cast<ASanctuaryBossMedallion2DPlane>(Owner);
		Mio = Game::Mio;
		MioMedallionComp = UMedallionPlayerComponent::GetOrCreate(Mio);
		MioRefs = UMedallionPlayerReferencesComponent::GetOrCreate(Mio);
		Zoe = Game::Zoe;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (!MioMedallionComp.IsMedallionCoopFlying())
			return false;
		if (Mio.bIsControlledByCutscene)
			return false;
		if (Zoe.bIsControlledByCutscene)
			return false;
		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (MioMedallionComp.IsMedallionCoopFlying())
			return false;
		return true;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		FlyingSpline = Plane.GetFlyingSpline();
		FTransform CurrentTransform = FlyingSpline.Spline.GetWorldTransformAtSplineDistance(Plane.AccSplineDistance.Value);
		AccTransform.SnapTo(CurrentTransform);
		Plane.SetActorLocation(AccTransform.Value.Location);
		Plane.SetActorRotation(FRotator::MakeFromZX(FVector::UpVector, AccTransform.Value.Rotation.ForwardVector));
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		Move2DPlane(DeltaTime);

		if (SanctuaryMedallionHydraDevToggles::Draw::Plane.IsEnabled())
		{
			Debug::DrawDebugPlane(Plane.ActorLocation, Plane.ActorForwardVector, Plane.PlaneExtents.Y, Plane.PlaneExtents.X, ColorDebug::White, 0.0, 8, 5.0);
			// Debug::DrawDebugArrow(ActorLocation, ActorLocation + ActorRightVector * 1500.0, 150.0, ColorDebug::Ruby, 10.0, 0.0, true);
		}
		if (SanctuaryMedallionHydraDevToggles::Draw::Spline.IsEnabled())
			FlyingSpline.Spline.DrawDebug();
	}

	private void Move2DPlane(float DeltaTime)
	{
		float FrameDistance = MedallionConstants::Flying::ForwardsFlyingSpeed * DeltaTime;
		if (Plane.AccSplineDistance.Value + FrameDistance >= FlyingSpline.Spline.SplineLength)
			ProceedToLoopIfNecessary();

		float SplineDistance = Math::Wrap(Plane.AccSplineDistance.Value + FrameDistance, 0.0, FlyingSpline.Spline.SplineLength);
		Plane.AccSplineDistance.SnapTo(SplineDistance);
		FTransform CurrentTransform = FlyingSpline.Spline.GetWorldTransformAtSplineDistance(Plane.AccSplineDistance.Value);
		if (AccTransform.Value.Location.Size() < KINDA_SMALL_NUMBER)
			AccTransform.SnapTo(CurrentTransform);
		AccTransform.AccelerateTo(CurrentTransform, 3.0, DeltaTime);
		Plane.SetActorLocation(AccTransform.Value.Location);
		Plane.SetActorRotation(FRotator::MakeFromZX(FVector::UpVector, AccTransform.Value.Rotation.ForwardVector));//CurrentTransform.Rotation.ForwardVector));
	}

	void ProceedToLoopIfNecessary()
	{
		bool bChanged = false;
		if (MioRefs.Refs.HydraAttackManager.Phase == EMedallionPhase::Flying1)
		{
			MioRefs.Refs.HydraAttackManager.SetPhase(EMedallionPhase::Flying1Loop);
			bChanged = true;
		}
		if (MioRefs.Refs.HydraAttackManager.Phase == EMedallionPhase::Flying2)
		{
			MioRefs.Refs.HydraAttackManager.SetPhase(EMedallionPhase::Flying2Loop);
			bChanged = true;
		}
		if (MioRefs.Refs.HydraAttackManager.Phase == EMedallionPhase::Flying3)
		{
			MioRefs.Refs.HydraAttackManager.SetPhase(EMedallionPhase::Flying3Loop);
			bChanged = true;
		}

		if (bChanged)
		{
			FlyingSpline = Plane.GetFlyingSpline();
			float ClosestDist = FlyingSpline.Spline.GetClosestSplineDistanceToWorldLocation(Plane.ActorLocation);
			Plane.AccSplineDistance.SnapTo(ClosestDist);
		}
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		Plane.AccSplineDistance.SnapTo(0.0);
		FTransform CurrentTransform = FlyingSpline.Spline.GetWorldTransformAtSplineDistance(Plane.AccSplineDistance.Value);
		AccTransform.SnapTo(CurrentTransform);
		Move2DPlane(0.0);
	}
};