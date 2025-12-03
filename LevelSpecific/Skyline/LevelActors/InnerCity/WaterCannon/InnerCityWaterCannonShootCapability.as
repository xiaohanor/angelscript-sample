class UInnerCityWaterCannonShootCapability : UHazeCapability
{
	default CapabilityTags.Add(CapabilityTags::GameplayAction);

	default TickGroup = EHazeTickGroup::Gameplay;

	AInnerCityWaterCannon WaterCannon;
	UInnerCityWaterCannonComponent PlayerComp;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		WaterCannon = Cast<AInnerCityWaterCannon>(Owner);
	
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (!WasActionStarted(ActionNames::PrimaryLevelAbility))
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (!WasActionStopped(ActionNames::PrimaryLevelAbility))
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		UInnerCityWaterCannonEventHandler::Trigger_OnStartSpray(WaterCannon);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		UInnerCityWaterCannonEventHandler::Trigger_OnStopSpray(WaterCannon);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
	
	}
};