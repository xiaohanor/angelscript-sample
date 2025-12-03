class UTundraBossGrabbedCapability : UTundraBossChildCapability
{
	float LoopDuration = 5;
	float TimeInLoop = 0;
	bool bCapabilityFinished = false;

	bool bShouldTickPunchActivationTimer = false;
	float PunchInteractionActivationTimer = 0;
	float PunchInteractionActivationTimerDuration = 1.0;
	
	bool bHasDeactivatedTreeGrabSeq = false;
	bool bHasStartedKeepIceKingDownButtonMash = false;

	UTundraPlayerSnowMonkeyIceKingBossPunchComponent PunchComp;
	UTundraBossHandlePlayerPunchViewComponent HandlePlayerPunchViewComp;
	UTreeGuardianHoldDownIceKingComponent HoldDownIceKingComponent;
	UTundraPlayerKeepIceKingDownComponent KeepIceKingDownComponent;

	ETundraBossGrabStates State = ETundraBossGrabStates::Struggle;
	FOnButtonMashCompleted OnButtonMashCompleted;

	bool bDoOnce = false;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Super::Setup();
		PunchComp = UTundraPlayerSnowMonkeyIceKingBossPunchComponent::GetOrCreate(Game::Mio);
		HoldDownIceKingComponent = UTreeGuardianHoldDownIceKingComponent::GetOrCreate(Game::Zoe);
		HandlePlayerPunchViewComp = UTundraBossHandlePlayerPunchViewComponent::GetOrCreate(Boss);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if(Boss.State == ETundraBossStates::Grabbed)
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if(bCapabilityFinished)
			return true;

		if(Boss.State != ETundraBossStates::Grabbed)
			return true;

		if(Boss.State == ETundraBossStates::PunchDamage)
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		State = ETundraBossGrabStates::Struggle;
		bHasDeactivatedTreeGrabSeq = false;
		bHasStartedKeepIceKingDownButtonMash = false;
		PunchInteractionActivationTimer = 0;
		Boss.RequestAnimation(ETundraBossAttackAnim::Struggle);
		Boss.SetIceKingCollisionEnabled(true);
		KeepIceKingDownComponent = UTundraPlayerKeepIceKingDownComponent::GetOrCreate(Game::Zoe);
		bDoOnce = false;
		
		Game::Zoe.ClearSettingsByInstigator(Boss);
		HandlePlayerPunchViewComp.StartZoeGrabCamera();

		Boss.BP_FFGrabbed();
		
		if(HasControl())
		{
			HoldDownIceKingComponent.OnMashCompleted.AddUFunction(this, n"OnMashCompleted");
			HoldDownIceKingComponent.OnMashFailed.AddUFunction(this, n"OnMashFailed");
		}
	}
	
	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{				
		bCapabilityFinished = false;
		Boss.CapabilityStopped(ETundraBossStates::Grabbed);
		Boss.SetIceKingCollisionEnabled(false);
		KeepIceKingDownComponent.KeepIceKingDownParams.bShouldActivateCapability = false;

		if(HasControl())
		{
			HoldDownIceKingComponent.OnMashCompleted.Unbind(this, n"OnMashCompleted");
			HoldDownIceKingComponent.OnMashFailed.Unbind(this, n"OnMashFailed");
		}

		Game::Zoe.StopButtonMash(this);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if(HasControl())
		{
			switch(State)
			{
				//Zoe button mashes to drag down the Ice King to an exposed state
				case ETundraBossGrabStates::Struggle:
				{	
					break;
				}

				//Button mash was successful and is going towards exposed MH
				case ETundraBossGrabStates::DraggedDown:
				{
					if(bDoOnce)
						return;

					Boss.CrumbActivateGrabbedKillCollision(true);
					CrumbMarkZoeCameraForDeactivation(1.5);
					CrumbSetMioControlSide(Boss.CurrentPhase, Boss.CurrentPhaseAttackStruct, Boss.State);
					bDoOnce = true;
					break;
				}

				//Ice King in exposed MH and can be damaged
				case ETundraBossGrabStates::Loop:
				{
					if(!bHasStartedKeepIceKingDownButtonMash)
					{
						bHasStartedKeepIceKingDownButtonMash = true;
						CrumbStartKeepIceKingDownButtonMash();
					}

 					TimeInLoop += DeltaTime;
										
					//Ran out of time, no damage was recieved from Mio - Stop the Timer if Mio has entered the MonkeyPunch Interaction
					if(TimeInLoop > LoopDuration && PunchComp.CurrentBossPunchTargetable == nullptr)
					{
						if(!KeepIceKingDownComponent.bIsMashingSufficient)
							CrumbIceKingGetBackUp();
					}
					break;
				}

				case ETundraBossGrabStates::MAX:
					break;
			}

			if (bShouldTickPunchActivationTimer)
			{
				PunchInteractionActivationTimer += DeltaTime;
				if (PunchInteractionActivationTimer >= PunchInteractionActivationTimerDuration)
				{
					bShouldTickPunchActivationTimer = false;
					CrumbEnablePunchInteraction();
				}
			}
		}
		
		if (HoldDownIceKingComponent.bButtonMashIsActive)
		{
			Boss.AnimInstance.StruggleBlendSpaceValue = (2 * HoldDownIceKingComponent.GetInterpolatedMashProgress()) - 1;
			Boss.TreeGrabSequenceScrubActor.ScrubSeqBasedOnMashProgress(HoldDownIceKingComponent.GetInterpolatedMashProgress());
		}			
	}

	UFUNCTION(CrumbFunction)
	void CrumbSetMioControlSide(ETundraBossPhases SyncedCurrentPhase, FTundraBossAttackQueueStruct SyncedCurrentPhaseAttackStruct, ETundraBossStates SyncedState)
	{
		Boss.SetActorControlSide(Game::Mio);
		
		if(!Game::Mio.HasControl())
			return;

		State = ETundraBossGrabStates::Loop;
		TimeInLoop = 0;
		bShouldTickPunchActivationTimer = true;

		Boss.State = SyncedState;
		Boss.CurrentPhase = SyncedCurrentPhase;
		Boss.CurrentPhaseAttackStruct = SyncedCurrentPhaseAttackStruct;
	}

	UFUNCTION(CrumbFunction)
	void CrumbStartKeepIceKingDownButtonMash()
	{
		if(Game::Zoe.HasControl())
		{
			FKeepIceKingDownParams Params;
			Params.Boss = Boss;
			Params.bShouldActivateCapability = true;
			UTundraPlayerKeepIceKingDownComponent::GetOrCreate(Game::Zoe).KeepIceKingDownParams = Params;
		}
	}

	UFUNCTION(CrumbFunction)
	void CrumbMarkZoeCameraForDeactivation(float DeactivationTime)
	{
		HandlePlayerPunchViewComp.MarkZoeGrabCameraForDeactivation(DeactivationTime, true);
	}

	UFUNCTION(CrumbFunction)
	void CrumbIceKingGetBackUp()
	{
		if(HasControl())
		{
			Boss.CrumbActivateGrabbedKillCollision(false);
		}
		
		KeepIceKingDownComponent.KeepIceKingDownParams.bShouldActivateCapability = false;
		Boss.SetPunchInteractionPhase02Active(false);
		Boss.RangedTreeInteractionTargetComp.ForceExitInteract();
		Boss.RangedTreeInteractionTargetComp.Disable(Boss);
		Game::Zoe.UnblockCapabilities(TundraShapeshiftingTags::ShapeshiftingInput, Boss);
		HandlePlayerPunchViewComp.MarkZoeGrabCameraForDeactivation(0);
		UTundraBoss_EffectHandler::Trigger_OnBreakFreeNoDamage(Boss);
		Boss.PushAttack(ETundraBossStates::BreakFree);
	}

	UFUNCTION(CrumbFunction)
	void CrumbEnablePunchInteraction()
	{	
		Boss.SetPunchInteractionPhase02Active(true);
	}

	UFUNCTION()
	private void OnMashCompleted(bool bIsIceKing)
	{
		CrumbMashCompleted();
	}

	UFUNCTION(CrumbFunction)
	void CrumbMashCompleted()
	{
		Boss.TreeGrabSequenceScrubActor.MashWasSuccessful();
		Game::Zoe.BlockCapabilities(TundraShapeshiftingTags::ShapeshiftingInput, Boss);
		UTundraBoss_EffectHandler::Trigger_OnFloored(Boss);
		Boss.RequestAnimation(ETundraBossAttackAnim::Grabbed);
		
		State = ETundraBossGrabStates::DraggedDown;
	}
	
	UFUNCTION()
	private void OnMashFailed()
	{
		CrumbMashFailed();
	}

	UFUNCTION(CrumbFunction)
	void CrumbMashFailed()
	{
		HandlePlayerPunchViewComp.MarkZoeGrabCameraForDeactivation(0);
		bCapabilityFinished = true;
		Boss.RangedTreeInteractionTargetComp.ForceExitInteract();
		Boss.RangedTreeInteractionTargetComp.Disable(Boss);
		
		if(HasControl())
			Boss.PushAttack(ETundraBossStates::BreakFreeFromStruggle);
	}
};