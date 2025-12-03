class UIslandJetpackLandRechargeCapability : UHazePlayerCapability
{
	default CapabilityTags.Add(CapabilityTags::GameplayAction);
	default CapabilityTags.Add(n"Jetpack");

	default TickGroup = EHazeTickGroup::AfterGameplay;

	default DebugCategory = n"Jetpack";

	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;

	AIslandJetpack Jetpack;

	UPlayerMovementComponent MoveComp;
	UIslandJetpackComponent JetpackComp;
	UPlayerSwingComponent SwingComp;

	UPlayerPerchComponent PerchComp;

	UIslandJetpackSettings JetpackSettings;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		JetpackComp = UIslandJetpackComponent::Get(Player);
		MoveComp = UPlayerMovementComponent::Get(Player);
		PerchComp = UPlayerPerchComponent::Get(Player);
		SwingComp = UPlayerSwingComponent::Get(Player);

		Jetpack = JetpackComp.Jetpack;

		JetpackSettings = UIslandJetpackSettings::GetSettings(Player);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if(JetpackComp.bHasInitialBoost)
			return false;

		if(MoveComp.IsOnWalkableGround())
			return true;

		if(PerchComp.State == EPlayerPerchState::PerchingOnPoint)
			return true;

		if(PerchComp.bIsGroundedOnPerchSpline)
			return true;

		if(SwingComp.IsCurrentlySwinging())
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if(JetpackComp.HasFullCharge())
			return true;
		
		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		JetpackComp.bHasInitialBoost = true;
		Jetpack.WorldSpaceWidget.OnLand();
		JetpackComp.bIsRecharging = true;

		UIslandJetpackEventHandler::Trigger_FuelStartRecharge(Jetpack);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		JetpackComp.SetChargeLevel(1.0, false);
		JetpackComp.bIsRecharging = false;

		UIslandJetpackEventHandler::Trigger_FuelFullyCharged(Jetpack);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		float RechargeFuel = Math::FInterpConstantTo(JetpackComp.GetChargeLevel(), 1.0, DeltaTime, JetpackSettings.ChargeLandReplenishSpeed);
		JetpackComp.SetChargeLevel(RechargeFuel, false);
	}
};