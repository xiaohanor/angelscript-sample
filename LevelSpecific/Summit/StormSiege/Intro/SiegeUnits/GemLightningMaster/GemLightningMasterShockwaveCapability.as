class UGemLightningMasterShockwaveCapability : UHazeCapability
{
	default CapabilityTags.Add(n"GemLightningMasterShockwaveCapability");
	
	default TickGroup = EHazeTickGroup::Gameplay;
	default TickGroupOrder = 100;

	AGemLightningMaster LightningMaster;
	UStormSiegeDetectPlayerComponent DetectComp;

	float NextAttackTime;

	bool bInCombat;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		DetectComp = UStormSiegeDetectPlayerComponent::Get(Owner);
		LightningMaster = Cast<AGemLightningMaster>(Owner);
	}

	UFUNCTION(BlueprintOverride)
	void PreTick(float DeltaTime)
	{
		if (!bInCombat && DetectComp.HasAvailablePlayers())
		{
			bInCombat = true;
			NextAttackTime = Time::GameTimeSeconds + LightningMaster.ShockwaveAttackDelay;
		}

		if (bInCombat && !DetectComp.HasAvailablePlayers())
		{
			bInCombat = false;
		}
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (Time::GameTimeSeconds < NextAttackTime)
			return false;
		
		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		return true;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		//Find and release spikes - alternate intervals of 2 (every even, then every odd index)
		NextAttackTime = Time::GameTimeSeconds + LightningMaster.ShockwaveWaitTime;
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
	}	
}