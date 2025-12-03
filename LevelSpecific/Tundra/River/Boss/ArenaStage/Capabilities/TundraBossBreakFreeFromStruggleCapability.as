class UTundraBossBreakFreeFromStruggleCapability : UTundraBossChildCapability
{
	float MaxWaitDuration;

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if(Boss.State != ETundraBossStates::BreakFreeFromStruggle)
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if(Boss.State != ETundraBossStates::BreakFreeFromStruggle)
			return true;

		if(ActiveDuration >= MaxWaitDuration)
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		MaxWaitDuration = Boss.AnimInstance.GetTundraBossAnimationDuration(ETundraBossAttackAnim::GetBackUpFromStruggle);

		Boss.RequestAnimation(ETundraBossAttackAnim::GetBackUpFromStruggle);
		UTundraBoss_EffectHandler::Trigger_OnBreakFreeFromStruggle(Boss);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		Boss.CapabilityStopped(ETundraBossStates::BreakFreeFromStruggle);
	}
};