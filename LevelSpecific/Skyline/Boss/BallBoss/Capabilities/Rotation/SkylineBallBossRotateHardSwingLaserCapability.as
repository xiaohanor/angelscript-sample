class USkylineBallBossRotateHardSwingLaserCapability : USkylineBallBossChildCapability
{
	default CapabilityTags.Add(SkylineBallBossTags::Rotation);

	int LastChildAlignCount = 0;

	float AngularSpeed = 30;

	float SliceStartTimestamp;
	float OvershootFactor;
	float SliceDuration;
	float PauseDuration;

	FVector TargetLocation;
	FVector TargetDriftDirection;

	FVector LocationOfTarget;
	FVector RotationAxis;
	float AccumulatedAngle = 0;
	FQuat OriginalQuat;
	FQuat TargetQuat;

	AHazeActor Zoe;
	AHazeActor Mio;

	bool bTargetZoe = true;

	int NumberOfSwings = 0;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Super::Setup();
		Zoe = Game::Zoe;
		Mio = Game::Mio;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		return BallBoss.bSwingLaser;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		return NumberOfSwings > BallBoss.NumLaserSwings;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		NumberOfSwings = 0;
		OvershootFactor = 1.2;
		SliceDuration = 1.5;
		PauseDuration = 1.0;

		AngularSpeed = 30.0;
		UpdateTarget();
		BallBoss.ResetTarget();
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		BallBoss.bSwingLaser = false;
		BallBoss.ResetTarget();
		BallBoss.BigLaserActor.DeactivateLaser();
	}

	private void UpdateTarget()
	{
		BallBoss.BigLaserActor.ActivateLaser();
		LocationOfTarget = bTargetZoe ? Zoe.ActorLocation : Mio.ActorLocation;
		FVector ToTarget = (LocationOfTarget - BallBoss.ActorLocation).GetSafeNormal();
		FQuat DiffBetweenBallAndTarget = ToTarget.ToOrientationQuat() * BallBoss.ActorQuat.Inverse();
		{
			float DiffAngle = Math::RadiansToDegrees(DiffBetweenBallAndTarget.GetAngle());
			FVector DiffAxis = DiffBetweenBallAndTarget.GetRotationAxis();
			FQuat MoreRotation = Math::RotatorFromAxisAndAngle(DiffAxis, DiffAngle + 30).Quaternion();
			DiffBetweenBallAndTarget = MoreRotation;
		}
		TargetQuat = DiffBetweenBallAndTarget * BallBoss.ActorQuat;

		OvershootFactor *= 1.5;
		bTargetZoe = !bTargetZoe;
		++NumberOfSwings;
		OriginalQuat = BallBoss.ActorQuat;
		SliceStartTimestamp = ActiveDuration;
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		AccumulatedAngle += AngularSpeed * DeltaTime;
		if (AccumulatedAngle > 360.0)
			AccumulatedAngle -= 360.0;
		if (AccumulatedAngle < 0.0)
			AccumulatedAngle += 360.0;

		float Alpha = Math::Clamp((ActiveDuration - SliceStartTimestamp) / SliceDuration, 0.0, 1.0);
		float SlerpAlpha = Math::EaseInOut(0.0, 1.0, Alpha, 3.0);
		FQuat TargetRotation = FQuat::Slerp(OriginalQuat, TargetQuat, SlerpAlpha);
		BallBoss.AcceleratedTargetRotation.AccelerateTo(TargetRotation, 0.1, DeltaTime);
		BallBoss.SetActorRotation(BallBoss.AcceleratedTargetRotation.Value);

		if (SliceStartTimestamp + SliceDuration + PauseDuration < ActiveDuration)
		{
			UpdateTarget();
		}
		else if (SliceStartTimestamp + SliceDuration < ActiveDuration)
		{
			BallBoss.BigLaserActor.DeactivateLaser();
		}
	
		int Granularity = 10;
		for (int i = 0; i < Granularity; ++i)
		{
			float ProjectionOutwards = 300.0 * i;
			ProjectionOutwards += 1500.0;
			Debug::DrawDebugArrow(BallBoss.ActorLocation + OriginalQuat.ForwardVector * ProjectionOutwards, BallBoss.ActorLocation + TargetQuat.ForwardVector * ProjectionOutwards, 5000.0, ColorDebug::Strawberry, 7.0);
		}
		Debug::DrawDebugString(BallBoss.ActorLocation, "" + NumberOfSwings, FLinearColor::White, 0.0, 2.0);
		Debug::DrawDebugPlane(BallBoss.ActorLocation, TargetQuat.UpVector, 1000.0, 1000.0, ColorDebug::Cerulean, 0.0, 5);
		Debug::DrawDebugLine(BallBoss.ActorLocation, BallBoss.ActorLocation + TargetRotation.UpVector * 3000.0, ColorDebug::Ultramarine, 12.0, 0.0, true);
	}
}
