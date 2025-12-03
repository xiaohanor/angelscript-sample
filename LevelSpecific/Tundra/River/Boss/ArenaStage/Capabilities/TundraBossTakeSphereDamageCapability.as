class UTundraBossTakeSphereDamageCapability : UTundraBossChildCapability
{	
	float GetBackUpTimer = 0;
	float GetBackUpTimerDuration = 8;
	bool bShouldGetBackUp = false;
	bool bBossDiesAfterPhase = false;
	int TimesRecievedPunchDamageInPhase03;

	bool bShouldTickPunchActivationTimer = false;
	float PunchInteractionActivationTimer = 0;
	float PunchInteractionActivationTimerDuration = 2.0;

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate(FTundraBossTakeSphereDamageParams& Params) const
	{
		if(Boss.State != ETundraBossStates::SphereDamage)
			return false;

		Params.TimesRecievedPunchDamageInPhase03 = Boss.TimesRecievedPunchDamageInPhase03;
		Params.bBossDiesAfterPhase = Boss.CurrentPhaseAttackStruct.bBossDiesAfterPhase;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate(FTundraBossTakeSphereDamageParams& Params) const
	{
		if(Boss.State == ETundraBossStates::SphereDamage)
			return false;

		Params.TimesRecievedPunchDamageInPhase03 = Boss.TimesRecievedPunchDamageInPhase03;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FTundraBossTakeSphereDamageParams Params)
	{
		bShouldGetBackUp = false;
		GetBackUpTimer = 0;
		bBossDiesAfterPhase = Params.bBossDiesAfterPhase;
		TimesRecievedPunchDamageInPhase03 = Params.TimesRecievedPunchDamageInPhase03;

		Boss.FallingIciclesManager.StopDroppingIcicles();
		Boss.RedIceManager.StopRedIce();
		
		UTundraBoss_EffectHandler::Trigger_TakeDamageHitByBall(Boss);		
		
		if(TimesRecievedPunchDamageInPhase03 == 0)
		{
			Boss.RequestAnimation(ETundraBossAttackAnim::HitBySphere);
		}
		else
		{
			Boss.RequestAnimation(ETundraBossAttackAnim::HitBySphereSecondTime);
		}

		Boss.MioIceChunk.DeactivateIceChunk();
		Boss.ZoeIceChunk.DeactivateIceChunk();
		Boss.SetIceKingCollisionEnabled(true);
		Boss.IceKingHitBySphere();

		if(HasControl())
			CrumbSetMioControlSide(Boss.CurrentPhase, Boss.CurrentPhaseAttackStruct, Boss.State);
	}

	UFUNCTION(CrumbFunction)
	void CrumbEnablePunchInteraction(int TimesRecievedPunchDamage)
	{
		if(TimesRecievedPunchDamageInPhase03 == 0)
		{
			Boss.SetPunchInteractionPhase03Active(true);
		}
		else
		{
			Boss.SetFinalPunchInteractionActive(true);
		}
	}

	UFUNCTION(CrumbFunction)
	void CrumbDisablePunchInteraction(bool bFinalPunch)
	{
		if(bFinalPunch)
			Boss.SetFinalPunchInteractionActive(false);
		else
			Boss.SetPunchInteractionPhase03Active(false);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FTundraBossTakeSphereDamageParams Params)
	{
		Boss.SetIceKingCollisionEnabled(false);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if(!HasControl())
			return;

		if (bShouldTickPunchActivationTimer)
		{
			PunchInteractionActivationTimer += DeltaTime;
			if (PunchInteractionActivationTimer >= PunchInteractionActivationTimerDuration)
			{
				bShouldTickPunchActivationTimer = false;
				CrumbEnablePunchInteraction(TimesRecievedPunchDamageInPhase03);
			}
		}

		GetBackUpTimer += DeltaTime;

		if(GetBackUpTimer >= GetBackUpTimerDuration && !bShouldGetBackUp)
		{
			bShouldGetBackUp = true;

			if(TimesRecievedPunchDamageInPhase03 == 0)
			{
				CrumbDisablePunchInteraction(false);
			}
			else
			{
				CrumbDisablePunchInteraction(true);
			}

			Boss.PushAttack(ETundraBossStates::GetBackUpAfterSphere);
		}
	}

	UFUNCTION(CrumbFunction)
	void CrumbSetMioControlSide(ETundraBossPhases SyncedCurrentPhase, FTundraBossAttackQueueStruct SyncedCurrentPhaseAttackStruct, ETundraBossStates SyncedState)
	{
		Boss.SetActorControlSide(Game::Mio);
		
		if(!Game::Mio.HasControl())
			return;

		PunchInteractionActivationTimer = 0;
		bShouldTickPunchActivationTimer = true;
		GetBackUpTimer = 0;
		Boss.State = SyncedState;
		Boss.CurrentPhase = SyncedCurrentPhase;
		Boss.CurrentPhaseAttackStruct = SyncedCurrentPhaseAttackStruct;
	}
};

struct FTundraBossTakeSphereDamageParams
{
	int TimesRecievedPunchDamageInPhase03;
	bool bBossDiesAfterPhase;
}