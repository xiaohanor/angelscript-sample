
struct FActiveStickSpin
{
	FInstigator Instigator;
	FStickSpinSettings Settings;
	FOnStickSpinStopped OnStopped;
};

struct FActiveStickSpinState
{
	FInstigator Instigator;
	FStickSpinState State;
};

class UStickSpinComponent : UActorComponent
{
	UPROPERTY()
	TSubclassOf<UStickSpinWidget> StickSpinWidget;

	TArray<FActiveStickSpin> ActiveSpins;
	TArray<FActiveStickSpinState> SpinState;

	void StartStickSpin(
		FStickSpinSettings Settings,
		FInstigator Instigator,
		FOnStickSpinStopped OnStopped)
	{
		if (!HasControl())
			return;

		for (FActiveStickSpin& Spin : ActiveSpins)
		{
			if (Spin.Instigator == Instigator)
			{
				devError(f"A stick spin with instigator {Instigator} is already active.");
				return;
			}
		}

		FActiveStickSpin Spin;
		Spin.Instigator = Instigator;
		Spin.Settings = Settings;
		Spin.OnStopped = OnStopped;

		ActiveSpins.Add(Spin);
	}

	void StopStickSpin(FInstigator Instigator)
	{
		if (!HasControl())
			return;

		for (int i = 0, Count = ActiveSpins.Num(); i < Count; ++i)
		{
			if (ActiveSpins[i].Instigator == Instigator)
			{
				ActiveSpins.RemoveAt(i);
				break;
			}
		}
	}

	FStickSpinState GetStickSpinState(FInstigator Instigator)
	{
		for (int i = 0, Count = SpinState.Num(); i < Count; ++i)
		{
			if (SpinState[i].Instigator == Instigator)
				return SpinState[i].State;
		}

		return FStickSpinState();
	}

	bool IsStickSpinActive(FInstigator Instigator)
	{
		for (int i = 0, Count = ActiveSpins.Num(); i < Count; ++i)
		{
			if (ActiveSpins[i].Instigator == Instigator)
				return true;
		}

		return false;
	}

	void SnapStickSpinState(FInstigator Instigator, FStickSpinState NewState)
	{
		if (!HasControl())
			return;

		if (!IsStickSpinActive(Instigator))
		{
			devError(f"No stick spin with instigator {Instigator} is active.");
			return;
		}

		FActiveStickSpinState& State = GetState(Instigator);
		State.State = NewState;
	}

	FActiveStickSpinState& GetState(FInstigator Instigator)
	{
		for (int i = 0, Count = SpinState.Num(); i < Count; ++i)
		{
			if (SpinState[i].Instigator == Instigator)
				return SpinState[i];
		}

		FActiveStickSpinState State;
		State.Instigator = Instigator;
		SpinState.Add(State);

		return SpinState.Last();
	}

	void ClearState(FInstigator Instigator)
	{
		for (int i = 0, Count = SpinState.Num(); i < Count; ++i)
		{
			if (SpinState[i].Instigator == Instigator)
			{
				SpinState.RemoveAt(i);
				break;
			}
		}
	}
};