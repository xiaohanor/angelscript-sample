class UTundraBossTakePunchDamageCapability : UTundraBossChildCapability
{
	int NumberOfPunches = 0;
	int MaxPunches = 6;
	bool bShouldTickDisableTimer = false;
	float DisableTimer = 0;
	float DisableTimeDurationPhase02 = 4.4;
	float DisableTimeDurationLastPhase = 2.5;
	float DisableTimeDurationToUse = 0;
	bool bHasPunched = false;
	bool bInLastPhase = false;
	float CurrentHealth = 1;
	float PunchDamage = 0;
	float HealthAfterDamagedInPhase = 0;

	bool bDebugPunch = false;

	UTundraBossHandlePlayerPunchViewComponent HandlePlayerPunchViewComponent;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Super::Setup();
		
		HandlePlayerPunchViewComponent = UTundraBossHandlePlayerPunchViewComponent::GetOrCreate(Boss);
		
		if(!Game::Mio.HasControl())
			return;

		auto PunchComp = UTundraPlayerSnowMonkeyIceKingBossPunchComponent::GetOrCreate(Game::GetMio());
		PunchComp.OnDealDamagePunch.AddUFunction(this, n"OnMonkeyDealDamageNotify");
		PunchComp.OnBackFlipStarted.AddUFunction(this, n"OnMonkeyBackFlipStarted");
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate(FTundraBossPunchDamageParams& Params) const
	{
		if(Boss.State != ETundraBossStates::PunchDamage)
			return false;

		Params.CurrentHealth = Boss.CurrentPhaseAttackStruct.HealthDuringPhase;
		Params.HealthAfterDamagedInPhase = Boss.CurrentPhaseAttackStruct.HealthAfterDamagedInPhase;
		Params.DisableTimeDurationToUse = Boss.IsInLastPhase() ? DisableTimeDurationLastPhase : DisableTimeDurationPhase02;
		Params.bInLastPhase = Boss.IsInLastPhase();
		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if(Boss.State == ETundraBossStates::PunchDamage)
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	void OnLogState(FTemporalLog TemporalLog)
	{
		TemporalLog.Value("bDebugPunch", bDebugPunch);
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FTundraBossPunchDamageParams Params)
	{
		bDebugPunch = false;
		
		auto PunchComp = UTundraPlayerSnowMonkeyIceKingBossPunchComponent::GetOrCreate(Game::GetMio());
		PunchComp.OnPunch.AddUFunction(this, n"OnMonkeyPunch");
		
		Boss.ActivateGrabbedKillCollision(false);

		CurrentHealth = Params.CurrentHealth;
		PunchDamage = (CurrentHealth - Params.HealthAfterDamagedInPhase) / MaxPunches;
		HealthAfterDamagedInPhase = Params.HealthAfterDamagedInPhase;
		
		DisableTimer = 0;
		NumberOfPunches = 0;
		bHasPunched = false;

		DisableTimeDurationToUse = Params.DisableTimeDurationToUse;
		bInLastPhase = Params.bInLastPhase;
		
		HandlePlayerPunchViewComponent.StartMioPunchCamera(bInLastPhase);

		if(bInLastPhase && HasControl())
		{			
			Boss.TimesRecievedPunchDamageInPhase03++;
		}
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		auto PunchComp = UTundraPlayerSnowMonkeyIceKingBossPunchComponent::GetOrCreate(Game::GetMio());
		PunchComp.OnPunch.Unbind(this, n"OnMonkeyPunch");

		bShouldTickDisableTimer = false;
		UTundraBoss_EffectHandler::Trigger_OnBreakFreeAfterDamage(Boss);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if(!HasControl())
			return;

		if (!bShouldTickDisableTimer)
			return;

		DisableTimer += DeltaTime;

		if(DisableTimer >= DisableTimeDurationToUse)
		{
			Boss.CapabilityStopped(ETundraBossStates::PunchDamage);
			bShouldTickDisableTimer = false;
		}
	}

	UFUNCTION()
	private void OnMonkeyDealDamageNotify()
	{
		if(!Game::Mio.HasControl())
			return;

		bDebugPunch = true;

		if (NumberOfPunches < MaxPunches - 1)
		{
			CurrentHealth -= PunchDamage;
			CrumbUpdateBossHealth(CurrentHealth);
		}
		else
		{
			CrumbUpdateBossHealth(HealthAfterDamagedInPhase);
		}
	}
	
	UFUNCTION()
	void OnMonkeyPunch()
	{
		if(!Game::Mio.HasControl())
			return;

		NumberOfPunches++;

		if (NumberOfPunches == MaxPunches - 1)
		{
			CrumbFinalPunchDealt();
		}

		if (!bHasPunched)
		{
			CrumbVO_TriggerMonkeyPunchStarted();
			bHasPunched = true;
		}
	}

	UFUNCTION(CrumbFunction)
	void CrumbVO_TriggerMonkeyPunchStarted()
	{
		UTundraBoss_EffectHandler::Trigger_OnMonkeyPunchStarted(Boss);
	}

	UFUNCTION(CrumbFunction)
	void CrumbFinalPunchDealt()
	{
		bShouldTickDisableTimer = true;
		
		if(bInLastPhase)
		{
			Boss.SetPunchInteractionPhase03Active(false);
		}
		else
		{
			Boss.SetPunchInteractionPhase02Active(false);
		}

		if(HasControl())
			CrumbSetZoeControlSide(Boss.CurrentPhase, Boss.CurrentPhaseAttackStruct, Boss.State, Boss.TimesRecievedPunchDamageInPhase03);
	}

	UFUNCTION()
	void OnMonkeyBackFlipStarted(ETundraPlayerSnowMonkeyIceKingBossPunchType PunchType)
	{
		CrumbMonkeyExitingInteraction();
	}

	UFUNCTION(CrumbFunction)
	void CrumbMonkeyExitingInteraction()
	{
		if(bInLastPhase)
		{

		}
		else
		{
			Boss.RangedTreeInteractionTargetComp.ForceExitInteract();
			Boss.RangedTreeInteractionTargetComp.Disable(Boss);
			Game::Zoe.UnblockCapabilities(TundraShapeshiftingTags::ShapeshiftingInput, Boss);
		}
			
			Timer::SetTimer(this, n"DeactivatePunchCamera", 1.5);
	}

	UFUNCTION()
	void DeactivatePunchCamera()
	{
		HandlePlayerPunchViewComponent.StopMioPunchCamera(bInLastPhase);
	}
	
	UFUNCTION(CrumbFunction)
	void CrumbUpdateBossHealth(float HealthAfterUpdate)
	{
		Boss.bHasTakenDamageInCurrentState = true;
		if(HealthAfterUpdate <= 0)
		{
			Boss.HealthComponent.TakeDamage(1, EDamageType::Default, Boss);
			Boss.BossFightFinished.Broadcast();
		}
		else
		{
			Boss.HealthComponent.SetCurrentHealth(HealthAfterUpdate);
			Boss.HealthBarComponent.UpdateHealthBarSettings();
		}
	}

	UFUNCTION(CrumbFunction)
	void CrumbSetZoeControlSide(ETundraBossPhases SyncedCurrentPhase, FTundraBossAttackQueueStruct SyncedCurrentPhaseAttackStruct, ETundraBossStates SyncedState, int SyncedTimesRecievedPunchDamageInPhase03)
	{
		Boss.SetActorControlSide(Game::Zoe);
		
		if(!Game::Zoe.HasControl())
			return;

		bShouldTickDisableTimer = true;
		Boss.State = SyncedState;
		Boss.CurrentPhase = SyncedCurrentPhase;
		Boss.CurrentPhaseAttackStruct = SyncedCurrentPhaseAttackStruct;
		Boss.TimesRecievedPunchDamageInPhase03 = SyncedTimesRecievedPunchDamageInPhase03;
	}
};

struct FTundraBossPunchDamageParams
{
	float CurrentHealth;
	float HealthAfterDamagedInPhase;
	float DisableTimeDurationToUse;
	bool bInLastPhase;
}