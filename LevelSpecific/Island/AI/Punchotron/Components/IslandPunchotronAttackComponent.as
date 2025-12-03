enum EIslandPunchotronAttackState
{
	SpinningAttack, // Deprecated
	HaywireAttack,
	CobraStrikeAttack,	
	WheelchairKickAttack,
	None,
}

// Assumed to be only used by control side.
class UIslandPunchotronAttackComponent : UActorComponent
{
	bool bEnableTaunt = false; 
	bool bIsAttacking = false; // For preventing other attack variants from activating during an attack.
	bool bIsInterruptAttack = false; // hack for selecting correct movement capability in proximity attack

	private EIslandPunchotronAttackState CurrentAttackState = EIslandPunchotronAttackState::None;

	TMap<EIslandPunchotronAttackState, uint> StateIndexMap;

	TArray<EIslandPunchotronAttackState> DisabledAttacks;

#if EDITOR
	TArray<uint> DevToggleDisabledIndices;

	void UpdateAttackState()
	{
		if (CurrentAttackIndex == 0 || DevToggleDisabledIndices.Contains(CurrentAttackIndex)) // none
			NextAttackState();
	}
#endif

	uint CurrentAttackIndex = 0; // none

	const uint MAX_ATTACK_INDEX = 1;

	bool bIsProximityAttackEnabled = true;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		bEnableTaunt = false;
		bIsAttacking = false;
		
		StateIndexMap.Add(EIslandPunchotronAttackState::None, 0);
		StateIndexMap.Add(EIslandPunchotronAttackState::CobraStrikeAttack, 1);
		//StateIndexMap.Add(EIslandPunchotronAttackState::HaywireAttack, 1);
		//StateIndexMap.Add(EIslandPunchotronAttackState::WheelchairKickAttack, 3);

		NextAttackState();
	}

	// Used for specific encounters to disable certain attacks from ever executing.
	void DisableAttack(EIslandPunchotronAttackState Attack)
	{
		DisabledAttacks.Add(Attack);
	}

	EIslandPunchotronAttackState GetAttackState() property
	{
		return CurrentAttackState;
	}

	void SetAttackState(EIslandPunchotronAttackState Attack)
	{
		CurrentAttackState = Attack;
		CurrentAttackIndex = GetAttackIndex(Attack);
	}

	void NextAttackState()
	{
		CurrentAttackIndex++;
		if (CurrentAttackIndex > MAX_ATTACK_INDEX)
			CurrentAttackIndex = 1;
		SetAttackByIndex(CurrentAttackIndex);
		if (DisabledAttacks.Contains(CurrentAttackState))
			NextAttackState();
#if EDITOR
		if (DevToggleDisabledIndices.Num() == int(MAX_ATTACK_INDEX))
		{
			SetAttackByIndex(StateIndexMap[EIslandPunchotronAttackState::None]);
		}
		// Prevent DevToggle from infinite recursion.
		else if (
			( DevToggleDisabledIndices.Contains(StateIndexMap[EIslandPunchotronAttackState::CobraStrikeAttack]) || DisabledAttacks.Contains(EIslandPunchotronAttackState::CobraStrikeAttack))
			&& 
			(DevToggleDisabledIndices.Contains(StateIndexMap[EIslandPunchotronAttackState::HaywireAttack]) || DisabledAttacks.Contains(EIslandPunchotronAttackState::HaywireAttack))
			)
		{
			SetAttackByIndex(StateIndexMap[EIslandPunchotronAttackState::None]);
		}
		else if (DevToggleDisabledIndices.Contains(CurrentAttackIndex))
		{
			NextAttackState();
		}
#endif
	}

	void SetRandomAttack()
	{
		uint AttackNum = uint(Math::RandRange(1, MAX_ATTACK_INDEX));
		SetAttackByIndex(AttackNum);
	}

	void SetAttackByIndex(uint Index)
	{
		for (auto StateMapElement : StateIndexMap)
		{
			if (StateMapElement.Value == Index)
			{
				CurrentAttackIndex = Index;
				CurrentAttackState = StateMapElement.Key;
				return;
			}
		}
		Throw("SetAttackByIndex has no State mapped to Index");
	}

	uint GetAttackIndex(EIslandPunchotronAttackState State)
	{		
		uint Index = 0;
		if (!StateIndexMap.Find(State, Index))
		{
			Throw("PunchotronAttackState has no Index mapped to State");
		}

		return Index;
	}
};