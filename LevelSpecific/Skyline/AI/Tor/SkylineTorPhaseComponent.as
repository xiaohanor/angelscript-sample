event void FSkylineTorPhaseComponentPhaseChangeSignature(ESkylineTorPhase NewPhase, ESkylineTorPhase OldPhase, ESkylineTorSubPhase NewSubPhase, ESkylineTorSubPhase OldSubPhase);
event void FSkylineTorPhaseComponentSubPhaseChangeSignature(ESkylineTorSubPhase NewSubPhase, ESkylineTorSubPhase OldSubPhase);
event void FSkylineTorPhaseComponentStateChangeSignature(ESkylineTorState NewState, ESkylineTorState OldState);

enum ESkylineTorPhase
{
	Idle,
	Entry,
	Grounded,
	Hovering,
	Gecko,
	Dead
}

enum ESkylineTorSubPhase
{
	None,
	EntryWait,
	EntryAttack,
	EntryEnter,
	GroundedSecond,
	HoveringSecond,
	GroundedShort,
	HoveringShort,
	GroundedDefensive,
	HoveringDefensive
}

enum ESkylineTorState
{
	None,
	Aggressive,
	Disarmed
}

class USkylineTorPhaseComponent : UActorComponent
{
	UBasicAIHealthComponent HealthComp;	

	ESkylineTorPhase InternalPhase = ESkylineTorPhase::Idle;
	ESkylineTorSubPhase InternalSubPhase = ESkylineTorSubPhase::None;
	ESkylineTorState InternalState = ESkylineTorState::None;
	
	FSkylineTorPhaseComponentPhaseChangeSignature OnPhaseChange;
	FSkylineTorPhaseComponentSubPhaseChangeSignature OnSubPhaseChange;
	FSkylineTorPhaseComponentStateChangeSignature OnStateChange;

	TArray<FSkylineTorPhaseSettings> PhaseSettings;	

	const float GroundedThreshold = 0.75;
	const float GroundedSecondThreshold = 0.5;
	const float HoveringThreshold = 0.25;
	const float HoveringSecondThreshold = 0;

	UFUNCTION()
	ESkylineTorPhase GetPhase() property
	{
		return InternalPhase;
	}

	UFUNCTION()
	ESkylineTorSubPhase GetSubPhase() property
	{
		return InternalSubPhase;
	}

	UFUNCTION()
	ESkylineTorState GetState() property
	{
		return InternalState;
	}

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		FSkylineTorPhaseSettings MeleeSettings;
		MeleeSettings.Phase = ESkylineTorPhase::Grounded;
		MeleeSettings.AllowedStates.Add(ESkylineTorState::Aggressive);
		MeleeSettings.AllowedStates.Add(ESkylineTorState::Disarmed);
		PhaseSettings.Add(MeleeSettings);
		HealthComp = UBasicAIHealthComponent::GetOrCreate(Owner);
	}

	UFUNCTION()
	void SetPhase(ESkylineTorPhase InPhase, ESkylineTorSubPhase InSubPhase = ESkylineTorSubPhase::None, ESkylineTorState InState = ESkylineTorState::None)
	{
		SetSubPhase(InSubPhase);

		bool bNewPhase = InPhase != InternalPhase;
		if(bNewPhase)
		{
			ESkylineTorPhase OldPhase = InternalPhase;
			InternalPhase = InPhase;

			bool bNewSubPhase = InSubPhase != InternalSubPhase;
			ESkylineTorSubPhase OldSubPhase = InternalSubPhase;
			InternalSubPhase = InSubPhase;

			OnPhaseChange.Broadcast(InPhase, OldPhase, InSubPhase, OldSubPhase);
			if(bNewSubPhase)
				OnSubPhaseChange.Broadcast(InSubPhase, OldSubPhase);
		}
		
		SetState(InState);
	}

	UFUNCTION()
	void SetSubPhase(ESkylineTorSubPhase InSubPhase, ESkylineTorState InState = ESkylineTorState::None)
	{
		bool bNewSubPhase = InSubPhase != InternalSubPhase;
		if(bNewSubPhase)
		{
			ESkylineTorSubPhase OldSubPhase = InternalSubPhase;
			InternalSubPhase = InSubPhase;
			OnSubPhaseChange.Broadcast(InSubPhase, OldSubPhase);
		}

		SetState(InState);
	}

	UFUNCTION()
	void SetState(ESkylineTorState InState)
	{
		ESkylineTorState NewState = ESkylineTorState::None;

		// Check allowed states in current phase
		if(InState != ESkylineTorState::None)
		{
			for(FSkylineTorPhaseSettings Setting : PhaseSettings)
			{
				if(Setting.Phase == InternalPhase)
				{
					if(Setting.AllowedStates.Contains(InState))
					{
						NewState = InState;
						break;
					}
				}
			}
		}

		bool bNewState = NewState != InternalState;
		if(!bNewState)
			return;

		ESkylineTorState OldState = InternalState;
		InternalState = NewState;

		if(bNewState)
			OnStateChange.Broadcast(NewState, OldState);
	}
}

struct FSkylineTorPhaseSettings
{
	ESkylineTorPhase Phase;
	TArray<ESkylineTorState> AllowedStates;
}