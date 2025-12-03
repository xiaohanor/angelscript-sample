class USketchbookBossIdleCapability : USketchbookBossChildCapability
{
	default CapabilityTags.Add(CapabilityTags::GameplayAction);


	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if(Boss.IdleTimer <= 0)
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if(Boss.IdleTimer <= 0)
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
		Boss.IdleTimer -= DeltaTime;
	}
};