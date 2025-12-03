class UIslandJetpackPhasableSlowdownCapability : UHazePlayerCapability
{
	default CapabilityTags.Add(CapabilityTags::Movement);
	default CapabilityTags.Add(IslandJetpack::BlockedWhileInPhasableMovement);

	default TickGroup = EHazeTickGroup::BeforeMovement;
	default TickGroupOrder = 30;
	default TickGroupSubPlacement = 3;
	default SeparateInactiveTick(EHazeTickGroup::BeforeMovement, 3, 1);
	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;

	default DebugCategory = IslandJetpack::Jetpack;


	UIslandJetpackComponent JetpackComp;
	AIslandJetpack Jetpack;
	UIslandJetpackSettings JetpackSettings;
	UPlayerMovementComponent MoveComp;
	USweepingMovementData Movement;
	UIslandJetpackPhasableComponent PhasableComp;

	FHazeAcceleratedFloat AccForwardSpeed;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		JetpackComp = UIslandJetpackComponent::Get(Owner);
		Jetpack = JetpackComp.Jetpack;

		JetpackSettings = UIslandJetpackSettings::GetSettings(Player);

		MoveComp = UPlayerMovementComponent::Get(Player);
		Movement = MoveComp.SetupSweepingMovementData();
		PhasableComp = UIslandJetpackPhasableComponent::GetOrCreate(Player);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (!PhasableComp.bQueuedPhasableSlowdown)
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (ActiveDuration > JetpackSettings.PhasableMovementSlowdownTotalDuration)
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		if (PhasableComp.PhasablePlatformSpline != nullptr)
		{
			auto SplinePos = PhasableComp.PhasablePlatformSpline.Spline.GetClosestSplinePositionToWorldLocation(Player.ActorCenterLocation);
			AccForwardSpeed.SnapTo(Player.ActorVelocity.DotProduct(SplinePos.WorldForwardVector));
		}
		else
			AccForwardSpeed.SnapTo(Player.ActorVelocity.DotProduct(Player.ActorForwardVector));

	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		PhasableComp.bQueuedPhasableSlowdown = false;
		if (!IsBlocked())
			PhasableComp.PhasablePlatformSpline = nullptr;
		
		UIslandJetpackEventHandler::Trigger_ThrusterBoostStop(Jetpack);
		Jetpack.InitialJetEffect.Deactivate();
		UCameraSettings::GetSettings(Player).FOV.Clear(n"PhasableMovement", 3.0);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		PhasableComp.AccFOV.AccelerateTo(0, JetpackSettings.PhasableMovementSlowdownFOVBlendDuration, DeltaTime);
		UCameraSettings::GetSettings(Player).FOV.ApplyAsAdditive(PhasableComp.AccFOV.Value, n"PhasableMovement");
	}
}