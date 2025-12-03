class USkylineBossTankEngineCapability : USkylineBossTankChildCapability
{
	default CapabilityTags.Add(SkylineBossTankTags::SkylineBossTank);
	default CapabilityTags.Add(SkylineBossTankTags::SkylineBossTankAction);

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Super::Setup();
		
		BossTank.BP_OnEngineStop();
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (BossTank.bIsControlledByCutscene)
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (BossTank.bIsControlledByCutscene)
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		BossTank.OnEngineStart.Broadcast();
		BossTank.BP_OnEngineStart();
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{		
		BossTank.OnEngineStop.Broadcast();
		BossTank.BP_OnEngineStop();
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
	}
}