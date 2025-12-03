class UBalancingTokenHealthLimitPlayerCapability : UHazePlayerCapability
{
	UPlayerHealthComponent HealthComp;
	UGentlemanComponent GentlemanComp;
	UBalancingSettings Settings;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		HealthComp = UPlayerHealthComponent::GetOrCreate(Owner);
		GentlemanComp = UGentlemanComponent::GetOrCreate(Owner);
		Settings = UBalancingSettings::GetSettings(Owner);
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
		float Factor = 1.0;
		int RemoveTokens;
		for(FBalancingSettingsTokenReductionHealthLimit Limit: Settings.TokenReductionHealthLimitFactors)
		{
			if(HealthComp.Health.CurrentHealth <= Limit.HealthFactor && Factor > Limit.HealthFactor)
			{
				Factor = Limit.HealthFactor;
				RemoveTokens = Limit.RemoveTokens;
			}
		}
		// TODO: Adjust tokens
	}
}