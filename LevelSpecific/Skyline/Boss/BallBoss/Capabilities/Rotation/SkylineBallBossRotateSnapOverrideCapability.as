struct FSkylineBallBossRotateSnapOverrideActivationParams
{
	ASkylineBallBossTopLaserSpline TopLaserSpline;
}

class USkylineBallBossRotateSnapOverrideCapability : USkylineBallBossChildCapability
{
	default CompoundNetworkSupport = EHazeCompoundNetworkSupport::OnlyCrumbNetwork;
	default CapabilityTags.Add(SkylineBallBossTags::Rotation);

	AHazeActor Zoe;

	FQuat StartQuat;
	ASkylineBallBossTopLaserSpline FollowTopLaserSpline;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Super::Setup();
		Zoe = Game::Zoe;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate(FSkylineBallBossRotateSnapOverrideActivationParams & Params) const
	{
		if (!BallBoss.bHasSnapRotation)
			return false;

		Params.TopLaserSpline = BallBoss.BigLaserActor.OverrideLaserSpline;
		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (!BallBoss.bHasSnapRotation)
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		BallBoss.ResetTarget();
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FSkylineBallBossRotateSnapOverrideActivationParams Params)
	{
		FollowTopLaserSpline = Params.TopLaserSpline;
		StartQuat = BallBoss.ActorQuat;
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		FVector ToTargetVector = (BallBoss.SnapTargetLocation - BallBoss.FakeRootComp.WorldLocation).GetSafeNormal();
		//Debug::DrawDebugSphere(BallBoss.SnapTargetLocation);
		FQuat ToTargetQuat = FRotator::MakeFromXZ(ToTargetVector, FVector::UpVector).Quaternion();
		if (SkylineBallBossDevToggles::DrawRotationTarget.IsEnabled())
		{
			Debug::DrawDebugCoordinateSystem(BallBoss.FakeRootComp.WorldLocation, ToTargetQuat.Rotator(), 2000.0);
			Debug::DrawDebugString(BallBoss.FakeRootComp.WorldLocation, "SNAP", ColorDebug::Magenta, 0.0, 6.0);
		}

#if EDITOR
		if (BallBoss.DisableAttacksRequesters.Num() > 0)
			TEMPORAL_LOG(BallBoss, "LaserSpline").Line("Rot", BallBoss.ActorCenterLocation, BallBoss.ActorCenterLocation + BallBoss.AcceleratedTargetRotation.Value.ForwardVector * 10000.0, 3.0, ColorDebug::Magenta);
#endif

		FQuat SmoothStartLerpedQuat = FQuat::FastLerp(StartQuat, ToTargetQuat, Math::Saturate(ActiveDuration));

		if (HasChangedTopLaserSpline())// can happen on zoe remote! Just fake smooth it out until we crumb reactivate capability
			BallBoss.AcceleratedTargetRotation.AccelerateTo(SmoothStartLerpedQuat, 1.0, DeltaTime);
		else
			BallBoss.AcceleratedTargetRotation.SnapTo(SmoothStartLerpedQuat);

		BallBoss.SetActorRotation(BallBoss.AcceleratedTargetRotation.Value);
	}

	bool HasChangedTopLaserSpline()
	{
		if (BallBoss.GetPhase() < ESkylineBallBossPhase::Top)
			return false;
		return FollowTopLaserSpline != nullptr && BallBoss.BigLaserActor.OverrideLaserSpline != nullptr 
			&& FollowTopLaserSpline != BallBoss.BigLaserActor.OverrideLaserSpline;
	}
}