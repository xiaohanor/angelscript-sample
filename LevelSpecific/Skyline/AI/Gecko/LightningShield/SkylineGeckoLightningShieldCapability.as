class USkylineGeckoLightningShieldCapability : UHazeCapability
{
	default NetworkMode = EHazeCapabilityNetworkMode::Local;

	USkylineGeckoComponent GeckoComp;
	float AllowHitsDuration = 0.0;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		GeckoComp = USkylineGeckoComponent::GetOrCreate(Owner);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (GeckoComp.bAllowBladeHits.Get())
			return false;
		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (AllowHitsDuration > 0.5)
			return true;
		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		GeckoComp.bShielded = true;
		AllowHitsDuration = 0.0;
		USkylineGeckoLightningShieldEffectsHandler::Trigger_OnActivate(Owner);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		GeckoComp.bShielded = false;
		USkylineGeckoLightningShieldEffectsHandler::Trigger_OnDeactivate(Owner);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if (GeckoComp.bAllowBladeHits.Get())
			AllowHitsDuration += DeltaTime;
		else
			AllowHitsDuration  = 0.0;
	}
}
