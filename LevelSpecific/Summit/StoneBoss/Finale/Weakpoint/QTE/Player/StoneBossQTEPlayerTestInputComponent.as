
enum EStoneBossQTEPlayerTestActionType
{
	None,
	Press,
	Hold,
	Release
}

struct FStoneBossQTEPlayerTestActionState
{
	FStoneBossQTEPlayerTestActionState(EStoneBossQTEPlayerTestActionType InActionType, float InHoldDuration)
	{
		ActionType = InActionType;
		HoldDuration = InHoldDuration;
	}
	FStoneBossQTEPlayerTestActionState(EStoneBossQTEPlayerTestActionType InActionType, float InHoldDuration, float InTimeWhenHoldStarted)
	{
		ActionType = InActionType;
		HoldDuration = InHoldDuration;
		TimeWhenHoldStarted = InTimeWhenHoldStarted;
	}
	float TimeWhenHoldStarted = 0;
	float HoldDuration = 0;
	EStoneBossQTEPlayerTestActionType ActionType;
};

class UStoneBossQTEPlayerTestInputComponent : UActorComponent
{
	TMap<FName, FStoneBossQTEPlayerTestActionState> ActionStates;
	default TickGroup = ETickingGroup::TG_LastDemotable;

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		if (!HasControl())
			return;

		for (auto Pair : ActionStates)
		{
			auto ActionState = Pair.Value;
			if (ActionState.ActionType == EStoneBossQTEPlayerTestActionType::None)
				continue;

			switch (ActionState.ActionType)
			{
				case EStoneBossQTEPlayerTestActionType::None:
					continue;
				case EStoneBossQTEPlayerTestActionType::Press:
					if (ActionState.HoldDuration <= SMALL_NUMBER)
					{
						Pair.Value.ActionType = EStoneBossQTEPlayerTestActionType::Release;
					}
					else
					{
						Pair.Value.ActionType = EStoneBossQTEPlayerTestActionType::Hold;
						Pair.Value.TimeWhenHoldStarted = Time::GameTimeSeconds;
					}
					break;
				case EStoneBossQTEPlayerTestActionType::Hold:
					if (Time::GetGameTimeSince(ActionState.TimeWhenHoldStarted) >= ActionState.HoldDuration)
						Pair.Value.ActionType = EStoneBossQTEPlayerTestActionType::Release;
					break;
				case EStoneBossQTEPlayerTestActionType::Release:
					Pair.Value.ActionType = EStoneBossQTEPlayerTestActionType::None;
					break;
			}
		}
	}

	bool IsActioning(FName ActionName)
	{
		if (!ActionStates.Contains(ActionName))
			return false;

		return ActionStates[ActionName].ActionType == EStoneBossQTEPlayerTestActionType::Hold || ActionStates[ActionName].ActionType == EStoneBossQTEPlayerTestActionType::Press;
	}

	bool WasActionStarted(FName ActionName)
	{
		if (!ActionStates.Contains(ActionName))
			return false;

		return ActionStates[ActionName].ActionType == EStoneBossQTEPlayerTestActionType::Press;
	}

	bool WasActionStopped(FName ActionName)
	{
		if (!ActionStates.Contains(ActionName))
			return false;

		return ActionStates[ActionName].ActionType == EStoneBossQTEPlayerTestActionType::Release;
	}

#if EDITOR
	UFUNCTION(DevFunction)
	void AddAction(FName ActionName, EStoneBossQTEPlayerTestActionType ActionType, float HoldDuration = 0)
	{
		if (ActionType == EStoneBossQTEPlayerTestActionType::None)
			return;
		if (ActionType == EStoneBossQTEPlayerTestActionType::Hold)
			ActionStates.Add(ActionName, FStoneBossQTEPlayerTestActionState(ActionType, HoldDuration, Time::GameTimeSeconds));
		else
			ActionStates.Add(ActionName, FStoneBossQTEPlayerTestActionState(ActionType, HoldDuration));
	}
#endif
};