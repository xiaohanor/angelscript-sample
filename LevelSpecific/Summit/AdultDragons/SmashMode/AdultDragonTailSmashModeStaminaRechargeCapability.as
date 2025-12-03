class UAdultDragonTailSmashModeStaminaRechargeCapability : UHazePlayerCapability
{
	default CapabilityTags.Add(CapabilityTags::GameplayAction);
	default CapabilityTags.Add(n"AdultDragon");

	default TickGroup = EHazeTickGroup::Gameplay;
	default TickGroupOrder = 100;

	default DebugCategory = n"AdultDragon";

	UAdultDragonTailSmashModeSettings Settings;

	UAdultDragonTailSmashModeComponent SmashModeComp;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Settings = UAdultDragonTailSmashModeSettings::GetSettings(Player);

		SmashModeComp = UAdultDragonTailSmashModeComponent::Get(Player);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if(SmashModeComp.bSmashModeActive)
			return false;
		
		if(SmashModeComp.SmashModeStamina >= Settings.SmashModeStaminaMax)
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if(SmashModeComp.bSmashModeActive)
			return true;
		
		if(SmashModeComp.SmashModeStamina >= Settings.SmashModeStaminaMax)
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		SmashModeComp.SmashModeStamina += Settings.SmashModeStaminaRecharge * DeltaTime;
		SmashModeComp.SmashModeStamina = Math::Clamp(SmashModeComp.SmashModeStamina, 0, Settings.SmashModeStaminaMax);
		// PrintToScreen(f"AirDashStamina : {SmashModeComp.SmashModeStamina}");
	}
};