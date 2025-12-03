enum ESummitDecimatorState
{
	PreBattleStart,			// Before battle started
	Idle,					// In pause.
	RunningAttackSequence, 	// Running substates
	JumpingDown,			// Phase transition jump
	JumpingDownRecover,		// Recover from landing in phase transition jump
	KnockedOut,				// Final phase weakpoint exposed
	TakingRollHitDamage,	// Hit weakpoint for massive damage
	KnockedOutRecover,		// Recovering from knocked out state
	PermaKnockedOut,		// Won't rise again. Well fought, old friend.
}

enum ESummitDecimatorBalconyMoveState
{
	Idle,
	TurningOutwards,
	TurningInwards,
	PausingForAttack,
	Running
}

enum ESummitDecimatorAttackState
{
	Pause,
	SpawningSpikeBombs,
	ChargingAndSpawningSpikeBombs,
	SpawningSpearShower,
	TrappingPlayer,
	EnablingSpinBeam,
	StartRotatingBalcony,
	StopRotatingBalcony,
	ShockwaveJumping,
	None,
}

struct FSubStates
{	
	void Add(ESummitDecimatorAttackState AttackState)
	{
		check(AttackState != ESummitDecimatorAttackState::Pause, "Adding PauseState without specifying a duration. Use AddPause instead.");
		AttackStates.Add(AttackState);
	}

	void AddPause(float Duration = 1.0)
	{
		AttackStates.Add(ESummitDecimatorAttackState::Pause);
		int Idx = AttackStates.Num() - 1;
		PauseDurations.Add(Idx, Duration);
	}

	TArray<ESummitDecimatorAttackState> AttackStates;
	TMap<int, float> PauseDurations;
}

class USummitDecimatorTopdownPhaseComponent : UActorComponent
{
	USummitDecimatorTopdownSettings Settings;
	USummitDecimatorSpikeBombSettings SpikeBombSettings;

	ESummitDecimatorState PrevState;
	ESummitDecimatorState CurrentState;
	ESummitDecimatorBalconyMoveState CurrentBalconyMoveState;

	int CurrentPhase = 1;
	private int PrevAttackStateIndex = 0;
	private int CurrentAttackStateIndex = 0;

	TMap<int, FSubStates> PhaseAttackStates;	

	AAISummitDecimatorTopdown Decimator;

	float RemainingActionDuration = 0;
	float RemainingTurnDuration = 0;
	float RemainingPauseDuration = 0;
	float CurrentPauseDuration = 0;

	int NumActiveSpikeBombs = 0;
	bool bHasActivePlayerTrap = false;

	int NumSpikeBombHits = 0;
	int NumRollHitsTaken = 0;

	bool bHasTriggeredInvulnerableState = false; // may be triggered from different capabilities.

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		Decimator = Cast<AAISummitDecimatorTopdown>(Owner);
		Settings = USummitDecimatorTopdownSettings::GetSettings(Decimator);
		SpikeBombSettings = USummitDecimatorSpikeBombSettings::GetSettings(Decimator);

		// Init space for the phase state lists
		PhaseAttackStates.Add(0, FSubStates());
		PhaseAttackStates.Add(1, FSubStates());
		PhaseAttackStates.Add(2, FSubStates());
		PhaseAttackStates.Add(3, FSubStates());
		PhaseAttackStates.Add(4, FSubStates());
		
		// Define Phase behaviours:
		
		// Phase 0 - Idle
		int PhaseIndex = 0;
		PhaseAttackStates[PhaseIndex].AddPause(1.0);

		// Phase 1 - From platform
		PhaseIndex = 1;
		// PhaseAttackStates[PhaseIndex].AddPause(1.0);
		PhaseAttackStates[PhaseIndex].Add(ESummitDecimatorAttackState::SpawningSpearShower);
		PhaseAttackStates[PhaseIndex].AddPause(5.0);
		PhaseAttackStates[PhaseIndex].Add(ESummitDecimatorAttackState::SpawningSpikeBombs);
		PhaseAttackStates[PhaseIndex].AddPause(2.0);


		// Phase 2 - Agitated from damaged platform
		PhaseIndex = 2;

		// To Pussel, whenever it may find him:
		PhaseAttackStates[PhaseIndex].AddPause(1.0);
		PhaseAttackStates[PhaseIndex].Add(ESummitDecimatorAttackState::StartRotatingBalcony);
		PhaseAttackStates[PhaseIndex].AddPause(1.0);
		PhaseAttackStates[PhaseIndex].Add(ESummitDecimatorAttackState::TrappingPlayer);
		// PhaseAttackStates[PhaseIndex].Add(ESummitDecimatorAttackState::SpawningSpikeBombs);
		PhaseAttackStates[PhaseIndex].AddPause(7.0);
		PhaseAttackStates[PhaseIndex].Add(ESummitDecimatorAttackState::EnablingSpinBeam);
		PhaseAttackStates[PhaseIndex].AddPause(1.0);
		PhaseAttackStates[PhaseIndex].Add(ESummitDecimatorAttackState::SpawningSpikeBombs);
		//PhaseAttackStates[PhaseIndex].Add(ESummitDecimatorAttackState::StopRotatingBalcony);
		
		// Phase 3 - Spinning charge attacks after platform broke down
		PhaseIndex = 3;
		PhaseAttackStates[PhaseIndex].Add(ESummitDecimatorAttackState::ChargingAndSpawningSpikeBombs);
		PhaseAttackStates[PhaseIndex].AddPause(4.0);
		PhaseAttackStates[PhaseIndex].Add(ESummitDecimatorAttackState::ShockwaveJumping);

		// Phase 4 - Play dead
		PhaseIndex = 4;
		PhaseAttackStates[PhaseIndex].AddPause(1.0);

		// Set initial state:
		CurrentState = ESummitDecimatorState::PreBattleStart;				// Main state
		CurrentBalconyMoveState = ESummitDecimatorBalconyMoveState::Idle;
		CurrentPhase = 1; 													// Phases range from 1 to 4. And 0, a debug idle state.
		CurrentAttackStateIndex = 0;										// AttackStates (substates) range from 0 to (NumStates - 1)
		PrevAttackStateIndex = 0;

#if EDITOR
		AttachParentActor = Owner.GetAttachParentActor();
#endif
	}

	void ChangeState(ESummitDecimatorState ToState)
	{
#if EDITOR
		//Owner.bHazeEditorOnlyDebugBool = true;
		if (Owner.bHazeEditorOnlyDebugBool)
			Print("Changing to state: " + ToState, Color=FLinearColor::Green);
#endif

		if (CurrentState == ToState)
			return;
		PrevState = CurrentState;
		CurrentState = ToState;
		// possibly reset attack state here
	}

	void TrySkipPauseState()
	{
		if (GetCurrentAttackState() == ESummitDecimatorAttackState::Pause)
			TryActivateNextAttackState();
	}


	void TryActivateNextAttackState()
	{		
		// Advance attack state index
		RemainingActionDuration = 0;
		PrevAttackStateIndex = CurrentAttackStateIndex;
		CurrentAttackStateIndex++;
		if (CurrentAttackStateIndex >= PhaseAttackStates[CurrentPhase].AttackStates.Num())
			CurrentAttackStateIndex = 0; // loop AttackState/Substate sequence

		// Handle pause state, set current pause duration
		if (GetCurrentAttackState() == ESummitDecimatorAttackState::Pause)
		{
			if (PhaseAttackStates[CurrentPhase].PauseDurations.Contains(CurrentAttackStateIndex))
			{
				CurrentPauseDuration = PhaseAttackStates[CurrentPhase].PauseDurations[CurrentAttackStateIndex];
				RemainingPauseDuration = CurrentPauseDuration;
			}
		}
		// Goto next state if any SpikeBomb is still lingering around since last spawn
		else if (GetCurrentAttackState() == ESummitDecimatorAttackState::SpawningSpikeBombs && NumActiveSpikeBombs > 0)
		{
			TryActivateNextAttackState();
		}
		// Goto next state if player trap is still active since last spawn
		else if (GetCurrentAttackState() == ESummitDecimatorAttackState::TrappingPlayer && bHasActivePlayerTrap)
		{
			TryActivateNextAttackState();
		}

		// Set move state
		UpdateMoveState();

#if EDITOR
		//Owner.bHazeEditorOnlyDebugBool = true;
		if (Owner.bHazeEditorOnlyDebugBool)
			Print("Try activating substate: " + GetCurrentAttackState(), Color=FLinearColor::Purple);

		FTemporalLog TemporalLog = TEMPORAL_LOG(this);		
		TemporalLog.Event("TryActivateNextAttackState");
#endif
	}

	void UpdateMoveState()
	{
		if (CurrentBalconyMoveState == ESummitDecimatorBalconyMoveState::Idle) // Movement is only initiated by SpinBalconyCapability. Should not leave idle move state from phasecomp.
			return;

		if (CurrentBalconyMoveState == ESummitDecimatorBalconyMoveState::PausingForAttack) // Was spawning or trapping. Turn for resume running.
		{
			CurrentBalconyMoveState = ESummitDecimatorBalconyMoveState::TurningOutwards;
			return;
		}
		
		ESummitDecimatorAttackState CurrentAttackState = GetCurrentAttackState();
		if (CurrentAttackState == ESummitDecimatorAttackState::SpawningSpikeBombs || CurrentAttackState == ESummitDecimatorAttackState::TrappingPlayer) // Turn inwards before attacking.
		{
			CurrentBalconyMoveState = ESummitDecimatorBalconyMoveState::TurningInwards;
			return;
		}
	}

	void ActivatePhase(int Num)
	{
		CurrentPhase = Num;
		PrevAttackStateIndex = 0;
		ResetAttackSequence();
		DecimatorTopdown::Animation::ClearFeatureBaseMovementTag(UBasicAIAnimationComponent::Get(Decimator)); // clear if set in phase 3
		
		#if EDITOR
				//Owner.bHazeEditorOnlyDebugBool = true;
				if (Owner.bHazeEditorOnlyDebugBool)
					PrintToScreen("Changing Phase to: Phase " + CurrentPhase, 5.0, Color=FLinearColor::DPink);
		#endif

		if (CurrentPhase == 3)
		{
			ChangeState(ESummitDecimatorState::JumpingDown); // JumpingDown also includes discarding platform/balcony
			Decimator.OnPhaseThreeStart.Broadcast();
			DecimatorTopdown::Animation::SetFeatureBaseMovementTagToSpinning(UBasicAIAnimationComponent::Get(Decimator));

			// Setup state if activated from checkpoint
			if (NumSpikeBombHits < Settings.PhaseOneNumSpikeBombHits + Settings.PhaseTwoNumSpikeBombHits)
				NumSpikeBombHits = Settings.PhaseOneNumSpikeBombHits + Settings.PhaseTwoNumSpikeBombHits;
		}
		else if (CurrentPhase == 4)
		{
			ChangeState(ESummitDecimatorState::PermaKnockedOut);
			Decimator.OnPhaseFourStart.Broadcast();
		}
	}

	void ActivateNextPhase()
	{
		CurrentPhase++;
		ActivatePhase(CurrentPhase);
	}

	void ResetAttackSequence()
	{
		CurrentAttackStateIndex = 0;
	}

	ESummitDecimatorAttackState GetCurrentAttackState() const
	{
		return PhaseAttackStates[CurrentPhase].AttackStates[CurrentAttackStateIndex];
	}

	ESummitDecimatorAttackState GetPrevAttackState() const
	{
		if (PrevAttackStateIndex > PhaseAttackStates[CurrentPhase].AttackStates.Num() - 1)
			return ESummitDecimatorAttackState::None;

		return PhaseAttackStates[CurrentPhase].AttackStates[PrevAttackStateIndex];
	}

	// Called from a crumbed function.
	void OnSpikeBombHit()
	{
		NumSpikeBombHits++;
		
		// Phase 3 hits
		if (NumSpikeBombHits > (Settings.PhaseOneNumSpikeBombHits + Settings.PhaseTwoNumSpikeBombHits))
		{
			// every three hits changes state into expose weakpoint
			UBasicAIHealthComponent AIHealthComp = UBasicAIHealthComponent::Get(Owner);
			bool bHasLowHealth = AIHealthComp.CurrentHealth <= SpikeBombSettings.DecimatorMinHealthLimit + SMALL_NUMBER;
			if (NumSpikeBombHits % Settings.PhaseThreeNumSpikeBombHits == 0 || bHasLowHealth)
				ChangeState(ESummitDecimatorState::KnockedOut);
		}		
		// Phase 2 hits
		else if (NumSpikeBombHits == (Settings.PhaseOneNumSpikeBombHits + Settings.PhaseTwoNumSpikeBombHits) )
		{
			ActivateNextPhase();			
		}
		// Phase 1 hits
		else if (NumSpikeBombHits == Settings.PhaseOneNumSpikeBombHits)
		{
			ActivateNextPhase();			
		}
	}


	//
	// DevFunctions
	//
#if EDITOR
	AActor AttachParentActor;	

	UFUNCTION(DevFunction)
	void DevChangeToPhase1()
	{
		Print("Changing Phase to : Phase 1", Color=FLinearColor::Green);
		CurrentState = ESummitDecimatorState::RunningAttackSequence;
		CurrentBalconyMoveState = ESummitDecimatorBalconyMoveState::Idle;
		NumSpikeBombHits = 0;
		NumRollHitsTaken = 0;
		CurrentPhase = 1;
		Owner.SetActorLocation(Decimator.HomeLocation);
		Cast<AAISummitDecimatorTopdown>(Owner).StopSlotAnimation();
		if (Owner.GetAttachParentActor() == nullptr)
			Owner.AttachToActor(AttachParentActor, AttachmentRule = EAttachmentRule::KeepWorld);
		ResetAttackSequence();
		EnableHealthBar();
		DecimatorTopdown::Animation::ClearFeatureBaseMovementTag(UBasicAIAnimationComponent::Get(Decimator));
	}

	UFUNCTION(DevFunction)
	void DevChangeToPhase2()
	{
		Print("Changing Phase to : Phase 2", Color=FLinearColor::Green);
		CurrentState = ESummitDecimatorState::RunningAttackSequence;
		NumSpikeBombHits = Settings.PhaseOneNumSpikeBombHits;
		NumRollHitsTaken = 0;
		Owner.SetActorLocation(Decimator.HomeLocation);
		if (Owner.GetAttachParentActor() == nullptr)
			Owner.AttachToActor(AttachParentActor, AttachmentRule = EAttachmentRule::KeepWorld);
		CurrentPhase = 2;
		ResetAttackSequence();
		EnableHealthBar();
		DecimatorTopdown::Animation::ClearFeatureBaseMovementTag(UBasicAIAnimationComponent::Get(Decimator));
	}

	UFUNCTION(DevFunction)
	void DevChangeToPhase3()
	{
		Print("Changing Phase to : Phase 3", Color=FLinearColor::Green);
		Owner.SetActorLocation(Decimator.HomeLocation);
		NumSpikeBombHits = Settings.PhaseOneNumSpikeBombHits + Settings.PhaseTwoNumSpikeBombHits;
		NumRollHitsTaken = 0;
		CurrentPhase = 3;
		ChangeState(ESummitDecimatorState::JumpingDown);
		ResetAttackSequence();
		EnableHealthBar();
		DecimatorTopdown::Animation::SetFeatureBaseMovementTagToSpinning(UBasicAIAnimationComponent::Get(Decimator));
	}

	UFUNCTION(DevFunction)
	private void EnableHealthBar()
	{
		UBasicAIHealthBarComponent HealthBarComp = UBasicAIHealthBarComponent::Get(Owner);
		HealthBarComp.SetHealthBarEnabled(true);
	}

	UFUNCTION(DevFunction)
	void DevChangeToPhase4()
	{
		Print("Changing Phase to : Phase 4", Color=FLinearColor::Green);		
		Owner.SetActorLocation(Owner.AttachmentRootActor.ActorLocation);
		NumSpikeBombHits = Settings.PhaseOneNumSpikeBombHits + Settings.PhaseTwoNumSpikeBombHits + 3; // arbitrary
		NumRollHitsTaken = 3;
		CurrentPhase = 4;
		ChangeState(ESummitDecimatorState::PermaKnockedOut);
		ResetAttackSequence();
		DecimatorTopdown::Animation::ClearFeatureBaseMovementTag(UBasicAIAnimationComponent::Get(Decimator));
	}

	UFUNCTION(DevFunction)
	void DevChangeToIdleStateInArena()
	{
		Print("Changing Phase to : Idle Phase", Color=FLinearColor::Green);		
		Owner.SetActorLocation(Owner.AttachmentRootActor.ActorLocation);		
		NumSpikeBombHits = 0;
		NumRollHitsTaken = 0;
		CurrentPhase = 0;
		UBasicAIAnimationComponent AnimComp = UBasicAIAnimationComponent::Get(Owner);
		AnimComp.Reset();
		ChangeState(ESummitDecimatorState::Idle);
		CurrentBalconyMoveState = ESummitDecimatorBalconyMoveState::Idle;
		ResetAttackSequence();
	}

	UFUNCTION(DevFunction)
	void DevChangeToIdleStateOnBalcony()
	{
		Print("Changing Phase to : Idle Phase", Color=FLinearColor::Green);		
		Owner.SetActorLocation(Decimator.HomeLocation);
		NumSpikeBombHits = 0;
		NumRollHitsTaken = 0;
		CurrentPhase = 0;
		UBasicAIAnimationComponent AnimComp = UBasicAIAnimationComponent::Get(Owner);
		AnimComp.Reset();
		ChangeState(ESummitDecimatorState::Idle);
		CurrentBalconyMoveState = ESummitDecimatorBalconyMoveState::Idle;
		ResetAttackSequence();
	}

	UFUNCTION(DevFunction)
	void DevShockwaveJump()
	{		
		CurrentState = ESummitDecimatorState::RunningAttackSequence;
		Owner.SetActorLocation(Decimator.HomeLocation);
		NumSpikeBombHits = Settings.PhaseTwoNumSpikeBombHits;
		CurrentPhase = 2; //temp hack, trigger jumpdown in ActivateNextPhase
		ActivateNextPhase();
		ResetAttackSequence();
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		//Owner.bHazeEditorOnlyDebugBool = true;
		if (Owner.bHazeEditorOnlyDebugBool)
		{
			PrintToScreen("Current Substate: " + GetCurrentAttackState(), 0.0, Color=FLinearColor::Teal);
			PrintToScreen("Prev Substate: " + GetPrevAttackState(), 0.0, Color=FLinearColor::Teal);
		}
		
		FTemporalLog TemporalLog = TEMPORAL_LOG(this);
		if (CurrentState == ESummitDecimatorState::Idle)
			TemporalLog.Status("" + CurrentState + "\n\n" + GetCurrentAttackState(), FLinearColor::Red);
		else if (CurrentState == ESummitDecimatorState::RunningAttackSequence && GetCurrentAttackState() == ESummitDecimatorAttackState::Pause)
			TemporalLog.Status("" + CurrentState + "\n\n" + GetCurrentAttackState(), FLinearColor::Yellow);
		else
			TemporalLog.Status("" + CurrentState + "\n\n" + GetCurrentAttackState(), FLinearColor::Green);
		TemporalLog.Value("CurrentPhase", CurrentPhase);
		TemporalLog.Value("CurrentAttackStateIndex", CurrentAttackStateIndex);
		TemporalLog.Value("Prev Substate", ""+GetPrevAttackState());

	
	}
#endif
};


