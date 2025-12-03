class USkylineBallBossRotateTowardsPlayerCapability : USkylineBallBossChildCapability
{
	default CompoundNetworkSupport = EHazeCompoundNetworkSupport::OnlyCrumbNetwork;
	default CapabilityTags.Add(SkylineBallBossTags::Rotation);

	AHazePlayerCharacter Zoe;
	AHazePlayerCharacter Mio;
	AHazeActor OnStageActor;
	FQuat TargetRotation;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Super::Setup();
		Zoe = Game::Zoe;
		Mio = Game::Mio;
		OnStageActor = BallBoss.OnStageActor;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		BallBoss.ResetTarget();
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		BallBoss.ResetTarget();
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		FVector TargetLocation = OnStageActor.ActorLocation;
		if (BallBoss.FocusPlayerComponent.CanFocusPlayer(Zoe))
			TargetLocation = Zoe.ActorLocation;
		else if (BallBoss.FocusPlayerComponent.CanFocusPlayer(Mio))
			TargetLocation = Mio.ActorLocation;

		float Duration = BallBoss.bExtraSlowRotateToZoe ? 5.0 : 2.0 ;
		if (BallBoss.bExtraSlowRotateToZoe && ActiveDuration > 5.0)
			BallBoss.bExtraSlowRotateToZoe = false;
		FVector ToAboveZoe = (TargetLocation + FVector::UpVector * 300.0) - BallBoss.ActorLocation;
		TargetRotation = FRotator::MakeFromXZ(ToAboveZoe.GetSafeNormal(), FVector::UpVector).Quaternion();

		if (SkylineBallBossDevToggles::DrawRotationTarget.IsEnabled())
			Debug::DrawDebugCoordinateSystem(BallBoss.ActorLocation, TargetRotation.Rotator(), 2000.0);

		BallBoss.AcceleratedTargetRotation.AccelerateTo(TargetRotation, Duration, DeltaTime);
		BallBoss.SetActorRotation(BallBoss.AcceleratedTargetRotation.Value);

		// Debug::DrawDebugSphere(BallBoss.AcceleratedTargetVector.Value, 120.0, 12, ColorDebug::Carrot, 50.0, 0.0, true);
		// Debug::DrawDebugLine(BallBoss.ActorLocation, BallBoss.ActorLocation + TargetRotation.ForwardVector * 1500.0, ColorDebug::Magenta, 15.0, 0.0, true);
	}
}