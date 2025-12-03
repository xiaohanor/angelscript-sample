class UTundraBossHiddenCapability : UTundraBossChildCapability
{
	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if(Boss.State != ETundraBossStates::Hidden)
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if(Boss.State != ETundraBossStates::Hidden)
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		Boss.HealthBarComponent.SetHealthBarEnabled(false);
		Boss.RequestAnimation(ETundraBossAttackAnim::Hidden);
		Boss.bBlockTauntPlayerDeaths = true;
	}
	
	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		Boss.HealthBarComponent.SetHealthBarEnabled(true);
		Boss.RequestAnimation(ETundraBossAttackAnim::Idle, true);
		Boss.SetActorHiddenInGame(false);
		Boss.bBlockTauntPlayerDeaths = false;
		
		if(HasControl())
			Boss.CrumbUpdateTundraBossHealthSettings(Boss.AttackPhases.FindOrAdd(Boss.CurrentPhase).HealthDuringPhase);
	}
};