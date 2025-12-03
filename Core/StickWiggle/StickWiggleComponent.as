struct FActiveStickWiggle
{
	FInstigator Instigator;
	FStickWiggleSettings Settings;
	FOnStickWiggleCompleted OnCompleted;
	FOnStickWiggleCanceled OnCanceled;
};

struct FActiveStickWiggleState
{
	FInstigator Instigator;
	FStickWiggleState State;
};

UCLASS(NotBlueprintable)
class UStickWiggleComponent : UActorComponent
{
	UPROPERTY()
	TSubclassOf<UStickWiggleWidget> StickWiggleWidget;

	TArray<FActiveStickWiggle> ActiveWiggles;
	TArray<FActiveStickWiggleState> WiggleState;

	void StartStickWiggle(
		FStickWiggleSettings Settings,
		FInstigator Instigator,
		FOnStickWiggleCompleted OnCompleted,
		FOnStickWiggleCanceled OnCanceled)
	{
		if (!HasControl())
			return;

		for (FActiveStickWiggle& Wiggle : ActiveWiggles)
		{
			if (Wiggle.Instigator == Instigator)
			{
				devError(f"A stick wiggle with instigator {Instigator} is already active.");
				return;
			}
		}

		FActiveStickWiggle Wiggle;
		Wiggle.Instigator = Instigator;
		Wiggle.Settings = Settings;
		Wiggle.OnCompleted = OnCompleted;
		Wiggle.OnCanceled = OnCanceled;

		ActiveWiggles.Add(Wiggle);
	}

	void StopStickWiggle(FInstigator Instigator)
	{
		if (!HasControl())
			return;

		for (int i = 0, Count = ActiveWiggles.Num(); i < Count; ++i)
		{
			if (ActiveWiggles[i].Instigator == Instigator)
			{
				ActiveWiggles.RemoveAt(i);
				break;
			}
		}
	}

	FStickWiggleState GetStickWiggleState(FInstigator Instigator) const
	{
		for (int i = 0, Count = WiggleState.Num(); i < Count; ++i)
		{
			if (WiggleState[i].Instigator == Instigator)
				return WiggleState[i].State;
		}

		return FStickWiggleState();
	}

	bool IsStickWiggleActive(FInstigator Instigator) const
	{
		for (int i = 0, Count = ActiveWiggles.Num(); i < Count; ++i)
		{
			if (ActiveWiggles[i].Instigator == Instigator)
				return true;
		}

		return false;
	}

	void SnapStickWiggleState(FInstigator Instigator, FStickWiggleState NewState)
	{
		if (!HasControl())
			return;

		if (!IsStickWiggleActive(Instigator))
		{
			devError(f"No stick spin with instigator {Instigator} is active.");
			return;
		}

		FActiveStickWiggleState& State = GetState(Instigator);
		State.State = NewState;
	}

	FActiveStickWiggleState& GetState(FInstigator Instigator)
	{
		for (int i = 0, Count = WiggleState.Num(); i < Count; ++i)
		{
			if (WiggleState[i].Instigator == Instigator)
				return WiggleState[i];
		}

		FActiveStickWiggleState State;
		State.Instigator = Instigator;
		WiggleState.Add(State);

		return WiggleState.Last();
	}

	void ClearState(FInstigator Instigator)
	{
		for (int i = 0, Count = WiggleState.Num(); i < Count; ++i)
		{
			if (WiggleState[i].Instigator == Instigator)
			{
				WiggleState.RemoveAt(i);
				break;
			}
		}
	}
};