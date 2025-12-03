struct FSkylineBallBossRotateAfterDetonatorHurtActivationParams
{
	FQuat TargetQuat;
}

class USkylineBallBossRotateAfterDetonatorHurtCapability : USkylineBallBossChildCapability
{
	default CompoundNetworkSupport = EHazeCompoundNetworkSupport::OnlyCrumbNetwork;
	default CapabilityTags.Add(SkylineBallBossTags::Rotation);

	FQuat OriginalQuat;
	FQuat TargetQuat;

	const float TotalDuration = 3.5;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Super::Setup();
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate(FSkylineBallBossRotateAfterDetonatorHurtActivationParams & Params) const
	{
		if (!BallBoss.bRecentlyGotDetonated)
			return false;

		const float RollAngle = 20.0;
		float RandomRollAngle = Math::RandBool() ? -RollAngle : RollAngle;
		FQuat AddedRoll = Math::RotatorFromAxisAndAngle(FVector::ForwardVector, RandomRollAngle).Quaternion();
		Params.TargetQuat = PickDirection() * AddedRoll;
		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		return ActiveDuration > TotalDuration;
	}

	private FQuat PickDirection() const
	{
		float RandomAngle = Math::RandRange(0.0, 360.0);
		FVector RandomOutwardDirection = Math::RotatorFromAxisAndAngle(BallBoss.ActorForwardVector, RandomAngle).ForwardVector;
		const float LookAwayAngle = 7.0;
		float RandomOffsetAngle = Math::RandBool() ? -LookAwayAngle : LookAwayAngle;
		FVector RandomOffet = Math::RotatorFromAxisAndAngle(RandomOutwardDirection, RandomOffsetAngle).RightVector;
		return FRotator::MakeFromXZ(RandomOffet.GetSafeNormal(), BallBoss.ActorUpVector).Quaternion();
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FSkylineBallBossRotateAfterDetonatorHurtActivationParams Params)
	{
		// Just a tiny jiggle
		TargetQuat = Params.TargetQuat;
		OriginalQuat = BallBoss.ActorQuat;
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		BallBoss.bRecentlyGotDetonated = false;
		BallBoss.ResetTarget();
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		const float OuchDuration = 0.35;
		const float BackDuration = TotalDuration - OuchDuration;
		if (ActiveDuration < OuchDuration)
		{
			if (SkylineBallBossDevToggles::DrawRotationTarget.IsEnabled())
				Debug::DrawDebugCoordinateSystem(BallBoss.ActorLocation, TargetQuat.Rotator(), 2000.0);
			BallBoss.AcceleratedTargetRotation.AccelerateTo(TargetQuat, OuchDuration, DeltaTime);
		}
		else
		{
			if (SkylineBallBossDevToggles::DrawRotationTarget.IsEnabled())
				Debug::DrawDebugCoordinateSystem(BallBoss.ActorLocation, OriginalQuat.Rotator(), 2000.0);
			BallBoss.AcceleratedTargetRotation.AccelerateTo(OriginalQuat, BackDuration, DeltaTime);
		}

		BallBoss.SetActorRotation(BallBoss.AcceleratedTargetRotation.Value);
	}
}