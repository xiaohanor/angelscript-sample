class UTundraBossSpawnCapability : UTundraBossChildCapability
{
	float Duration;

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if(Boss.State != ETundraBossStates::Spawn)
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if(ActiveDuration > Duration)
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		Duration = Boss.AnimInstance.GetTundraBossAnimationDuration(ETundraBossAttackAnim::Spawn);

		Boss.ApplySettings(Boss.HealthBarSetting, this, EHazeSettingsPriority::Override);
		Boss.HealthBarComponent.UpdateHealthBarSettings();
		Boss.SetActorHiddenInGame(false);
		Boss.RequestAnimation(ETundraBossAttackAnim::Spawn);
		Boss.OnAttackEventHandler(Duration);
		
		if(!HasControl())
			return;	
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		Boss.CapabilityStopped(ETundraBossStates::Spawn);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
	}
};