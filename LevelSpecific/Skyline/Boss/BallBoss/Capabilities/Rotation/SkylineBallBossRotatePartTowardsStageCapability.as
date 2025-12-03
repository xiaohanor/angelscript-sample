class USkylineBallBossRotatePartTowardsStageCapability : USkylineBallBossChildCapability
{
	default CompoundNetworkSupport = EHazeCompoundNetworkSupport::OnlyCrumbNetwork;
	default CapabilityTags.Add(SkylineBallBossTags::Rotation);

	AHazeActor OnStageActor;
	int LastChildAlignCount = 0;

	FQuat TargetQuat;
	bool UseAcceleration = false;
	bool bContinuousUpdate = true;
	bool bSnapOverTime = false;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Super::Setup();
		OnStageActor = BallBoss.OnStageActor;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (BallBoss.OnStageActor == nullptr)
			return false;
		return BallBoss.NumRotationTargets() > 0;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		return BallBoss.NumRotationTargets() <= 0;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		LastChildAlignCount = BallBoss.NumRotationTargets();
		UpdateTarget();
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		BallBoss.ResetTarget();
	}

	private void UpdateTarget()
	{
		if (BallBoss.NumRotationTargets() == 0)
			return;

		FBallBossAlignRotationData Target = BallBoss.GetCurrentRotationTarget();
		UseAcceleration = Target.bAccelerateAlignTowardsTarget;
		bContinuousUpdate = Target.bContinuousUpdate;
		bSnapOverTime = Target.bSnapOverTime;

		FVector FromBallToPart;
		if (Target.BallLocalDirection.Size() > KINDA_SMALL_NUMBER)
			FromBallToPart = BallBoss.ActorRotation.RotateVector(Target.BallLocalDirection);
		else
			FromBallToPart = (Target.PartComp.WorldLocation - BallBoss.ActorLocation).GetSafeNormal();

		FQuat PartWorldRot = FromBallToPart.ToOrientationQuat();
		FVector TargetLocation = Target.OverrideTargetComp != nullptr ? Target.OverrideTargetComp.WorldLocation : OnStageActor.ActorLocation;
		TargetLocation.Z += Target.HeightOffset;
		FVector ToTarget = (TargetLocation - BallBoss.ActorLocation).GetSafeNormal();
		FQuat DiffBetweenTargetAndPart = ToTarget.ToOrientationQuat() * PartWorldRot.Inverse();
		if (Target.bUseRandomOffset)
		{
			float LessAngle = Math::RandRange(Settings.ExtrudeAlignRotOffsetMin, Settings.ExtrudeAlignRotOffsetMax);
			float DiffAngle = Math::RadiansToDegrees(DiffBetweenTargetAndPart.GetAngle());
			DiffAngle = Math::Clamp(DiffAngle - LessAngle, 0.0, Math::Abs(DiffAngle));
			FVector DiffAxis = DiffBetweenTargetAndPart.GetRotationAxis();
			FQuat LessRotation = Math::RotatorFromAxisAndAngle(DiffAxis, DiffAngle).Quaternion();
			DiffBetweenTargetAndPart = LessRotation;
		}
		TargetQuat = DiffBetweenTargetAndPart * BallBoss.ActorQuat;
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		BallBoss.LogRotationTargets();

		if (BallBoss.NumRotationTargets() > LastChildAlignCount)
			LastChildAlignCount = BallBoss.NumRotationTargets();
		
		if (BallBoss.NumRotationTargets() < LastChildAlignCount)
		{
			FVector PreviousVelocityAxis = BallBoss.AcceleratedTargetRotation.VelocityAxisAngle;
			BallBoss.AcceleratedTargetRotation.SnapTo(BallBoss.ActorRotation.Quaternion(), PreviousVelocityAxis.GetSafeNormal(), PreviousVelocityAxis.Size());
			LastChildAlignCount = BallBoss.NumRotationTargets();
			UpdateTarget();
		}
		else if (bContinuousUpdate)
			UpdateTarget();

		if (UseAcceleration)
		{
			float Duration = 0.1;
			if (bSnapOverTime)
			{
				float OverTimeAlpha = Math::Clamp(ActiveDuration / 0.1, 0.0, 1.0);
				Duration = Math::Lerp(0.1, 0.001, OverTimeAlpha);
			}
			BallBoss.AcceleratedTargetRotation.AccelerateTo(TargetQuat, Duration, DeltaTime);
		}
		else
			BallBoss.AcceleratedTargetRotation.SpringTo(TargetQuat, Settings.ExtrudeRotateStiffness, Settings.ExtrudeRotateDampening, DeltaTime);

		if (SkylineBallBossDevToggles::DrawRotationTarget.IsEnabled())
			Debug::DrawDebugCoordinateSystem(BallBoss.ActorLocation, TargetQuat.Rotator(), 2000.0);

		BallBoss.SetActorRotation(BallBoss.AcceleratedTargetRotation.Value);

		// FVector FromBallToChild = (BallBoss.AlignTowardsStageDatas[0].WorldLocation - BallBoss.ActorLocation).GetSafeNormal();
		//Debug::DrawDebugLine(BallBoss.ActorLocation, BallBoss.ActorLocation + FromBallToChild * 3500.0, ColorDebug::Carrot, 50.0, 0.0, true);
		// Debug::DrawDebugCoordinateSystem(BallBoss.ActorLocation, FRotator(), 3000.0, 3.0, 0.0, true);
		// Debug::DrawDebugLine(BallBoss.ActorLocation, BallBoss.ActorLocation + TargetQuat.ForwardVector * 1500.0, ColorDebug::Leaf, 15.0, 0.0, true);
		// Debug::DrawDebugLine(BallBoss.ActorLocation, BallBoss.ActorLocation + TargetQuat.ForwardVector * 1500.0, ColorDebug::Magenta, 15.0, 0.0, true);
	}
}