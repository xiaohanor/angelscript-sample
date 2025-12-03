class UTundraBossStopRedIceCapability : UTundraBossChildCapability
{
	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Super::Setup();
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if(Boss.State != ETundraBossStates::StopRedIce)
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
		Boss.RedIceManager.StopRedIce();
		Boss.OnAttackEventHandler(-1);		
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		Boss.CapabilityStopped(ETundraBossStates::StopRedIce);
	}
};