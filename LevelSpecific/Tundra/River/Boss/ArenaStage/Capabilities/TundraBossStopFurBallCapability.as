class UTundraBossStopFurballCapability : UTundraBossChildCapability
{
	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Super::Setup();
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if(Boss.State != ETundraBossStates::StopFurball)
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
		// Boss.MioIceChunk.MarkForDeactivation();
		// Boss.ZoeIceChunk.MarkForDeactivation();
		Boss.OnAttackEventHandler(-1);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		Boss.CapabilityStopped(ETundraBossStates::StopFurball);
	}
};