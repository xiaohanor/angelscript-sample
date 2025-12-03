class UTundraBossSetupWaitCapability : UTundraBossSetupChildCapability
{
	float MaxWaitDuration = 1.5;

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if(Boss.State != ETundraBossSetupStates::Wait)
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if(Boss.State != ETundraBossSetupStates::Wait)
			return true;

		if(ActiveDuration >= MaxWaitDuration)
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		UTundraBossSetup_EffectHandler::Trigger_OnWait(Boss);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		if(HasControl())
			Boss.CrumbProgressQueue();
	}
};