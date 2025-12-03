class UTundraBossSetupAppearCapability : UTundraBossSetupChildCapability
{
	float CapabilityTimer;
	float CapabilityTimerDuration = 8;

	float HiddenInGameTimer;
	float HiddenInGameTimerDuration = 0.5;
	bool bHasToggledVisibility = false;

	float DisappearTimer = 0;
	float DisappearTimerDuration = 6.5;
	bool bShouldTickDisappearTimer = false;

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if(Boss.State != ETundraBossSetupStates::Appear)
			return false;

		if(Boss.bHasEnteredArena)
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (CapabilityTimer >= CapabilityTimerDuration)
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		UTundraBossSetup_EffectHandler::Trigger_OnBossAppear(Boss);
		
		if(!HasControl())
			return;

		CapabilityTimer = 0;
		DisappearTimer = 0;
		bShouldTickDisappearTimer = true;
		Boss.CrumbActivateAppear();
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		if (HasControl())
			Boss.CrumbProgressQueue();
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		CapabilityTimer += DeltaTime;

		if(!bHasToggledVisibility)
		{
			HiddenInGameTimer += DeltaTime;
			if(HiddenInGameTimer >= HiddenInGameTimerDuration)
			{
				bHasToggledVisibility = true;
				Boss.SetTundraBossHiddenInGame(false);
			}
		}

		if (!bShouldTickDisappearTimer)
			return;

		DisappearTimer += DeltaTime;
		if (DisappearTimer >= DisappearTimerDuration)
		{
			bShouldTickDisappearTimer = false;
			CrumbBossDisappeared();
		}
	}

	UFUNCTION(CrumbFunction)
	void CrumbBossDisappeared()
	{
		UTundraBossSetup_EffectHandler::Trigger_OnBossDisappear(Boss);
	}
};