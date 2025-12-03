class UTundraBossWaitCapability : UTundraBossChildCapability
{
	float Duration = 2.4;

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if(Boss.State != ETundraBossStates::Wait)
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if(Boss.State != ETundraBossStates::Wait)
			return true;

		if(ActiveDuration >= Duration)
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		Boss.RequestAnimation(ETundraBossAttackAnim::Wait);
		Boss.OnAttackEventHandler(Duration);	
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		Boss.CapabilityStopped(ETundraBossStates::Wait);
	}
};