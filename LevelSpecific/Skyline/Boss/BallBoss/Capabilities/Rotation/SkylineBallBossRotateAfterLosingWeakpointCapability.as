struct FSkylineBallBossRotateAfterLosingWeakpointActivationParams
{
	FQuat TargetQuat;
}

class USkylineBallBossRotateAfterLosingWeakpointCapability : USkylineBallBossChildCapability
{
	default CompoundNetworkSupport = EHazeCompoundNetworkSupport::OnlyCrumbNetwork;
	default CapabilityTags.Add(SkylineBallBossTags::Rotation);

	FQuat TargetQuat;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Super::Setup();
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate(FSkylineBallBossRotateAfterLosingWeakpointActivationParams& Params) const
	{
		if (!BallBoss.bRecentlyLostWeakpoint)
			return false;

		// Just a tiny jiggle
		FQuat SlightJiggleQuat = FRotator::MakeFromEuler(FVector(GetRandomJiggleAngle(), GetRandomJiggleAngle(), GetRandomJiggleAngle())).Quaternion();
		Params.TargetQuat = SlightJiggleQuat * BallBoss.ActorQuat;
		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		return ActiveDuration > 0.5;
	}

	float GetRandomJiggleAngle() const
	{
		return Math::RandRange(-15.0, 15.0);
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FSkylineBallBossRotateAfterLosingWeakpointActivationParams Params)
	{
		TargetQuat = Params.TargetQuat;
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		BallBoss.bRecentlyLostWeakpoint = false;
		BallBoss.ResetTarget();
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		// if (SkylineBallBossDevToggles::DrawRotationTarget.IsEnabled())
		// 	Debug::DrawDebugCoordinateSystem(BallBoss.ActorLocation, TargetQuat.Rotator(), 2000.0);
		// BallBoss.AcceleratedTargetRotation.SpringTo(TargetQuat, Settings.ExtrudeRotateStiffness, Settings.ExtrudeRotateDampening, DeltaTime);
		// BallBoss.SetActorRotation(BallBoss.AcceleratedTargetRotation.Value);
	}
}
