
enum EDoubleButtonMashType
{
	None,
	Primary,
	Secondary,
}

struct FActiveButtonMash
{
	FInstigator Instigator;
	FButtonMashSettings Settings;
	FOnButtonMashCompleted OnCompleted;
	FOnButtonMashCompleted OnCanceled;
	EDoubleButtonMashType DoubleType = EDoubleButtonMashType::None;

	bool IsDoubleMash() const
	{
		return DoubleType != EDoubleButtonMashType::None;
	}

	bool DoesProgressCountAsCompleted(float Progress) const
	{
		if (Settings.ProgressionMode == EButtonMashProgressionMode::MashRateOnly)
			return false;
		if (Settings.ProgressionMode == EButtonMashProgressionMode::MashRateOnlyIgnoreAutomatic)
			return false;

		if (Settings.ProgressionMode == EButtonMashProgressionMode::StartFullDecayDown)
			return Progress <= 0.0;
		else
			return Progress >= 1.0;
	}
};

struct FButtonMashState
{
	FInstigator Instigator;
	float CurrentProgress = 0.0;
	float MashRate = 0.0;
	bool bIsMashRateSufficient = false;
	float GainMultiplier = 1.0;
	bool bAllowCompletion = true;
};

event void FOnButtonMashVisualPulse();

class UButtonMashComponent : UActorComponent
{
	UPROPERTY()
	TSubclassOf<UButtonMashWidget> ButtonMashWidget;

	TArray<FActiveButtonMash> ActiveMashes;
	TArray<FButtonMashState> MashState;
	FOnButtonMashVisualPulse OnVisualPulse;

	void StartButtonMash(
		FButtonMashSettings Settings,
		FInstigator Instigator,
		FOnButtonMashCompleted OnCompleted,
		FOnButtonMashCompleted OnCanceled,
		EDoubleButtonMashType DoubleType)
	{
		if (!HasControl())
			return;

		for (FActiveButtonMash& Mash : ActiveMashes)
		{
			if (Mash.Instigator == Instigator)
			{
				devError(f"A button mash with instigator {Instigator} is already active.");
				return;
			}
		}

		FActiveButtonMash Mash;
		Mash.Instigator = Instigator;
		Mash.Settings = Settings;
		Mash.OnCompleted = OnCompleted;
		Mash.OnCanceled = OnCanceled;
		Mash.DoubleType = DoubleType;
			

		// If the setting to remove button mashes is on, turn it into a button hold
		ApplyRemoveButtonMashesSetting(Mash.Settings);

		// Double mashes can't be cancelable for network reasons
		if (Mash.IsDoubleMash() && Mash.Settings.bAllowPlayerCancel)
		{
			devError("Double button mashes cannot be set to allow cancel for network sync reasons.");
			Mash.Settings.bAllowPlayerCancel = false;
		}

		ActiveMashes.Add(Mash);
	}

	void ApplyRemoveButtonMashesSetting(FButtonMashSettings& Settings)
	{
		bool bRemoveButtonMashes = false;
		if (Owner == Game::Mio)
		{
			if (ButtonMash::CVar_RemoveButtonMashes_Mio.GetInt() == 1)
				bRemoveButtonMashes = true;
		}
		else
		{
			if (ButtonMash::CVar_RemoveButtonMashes_Zoe.GetInt() == 1)
				bRemoveButtonMashes = true;
		}

		if (bRemoveButtonMashes)
		{
			switch (Settings.Mode)
			{
				case EButtonMashMode::ButtonMash:
					Settings.Mode = EButtonMashMode::ButtonHold;
				break;
				case EButtonMashMode::ButtonHold:
				break;
			}
		}
	}

	void StopButtonMash(FInstigator Instigator, bool bNetworkSafe = false)
	{
		if (!HasControl())
			return;

		for (int i = 0, Count = ActiveMashes.Num(); i < Count; ++i)
		{
			if (ActiveMashes[i].Instigator == Instigator)
			{
				if (!bNetworkSafe && ActiveMashes[i].IsDoubleMash())
				{
					devError("Double button mashes cannot be stopped with StopButtonMash for network safety reasons.");
					break;
				}

				ActiveMashes.RemoveAt(i);
				break;
			}
		}
	}

	float GetButtonMashProgress(FInstigator Instigator) const
	{
		for (int i = 0, Count = MashState.Num(); i < Count; ++i)
		{
			if (MashState[i].Instigator == Instigator)
				return Math::Saturate(MashState[i].CurrentProgress);
		}

		return 0.0;
	}

	void GetButtonMashCurrentRate(FInstigator Instigator, float&out MashRate, bool&out bIsMashRateSufficient)
	{
		for (int i = 0, Count = MashState.Num(); i < Count; ++i)
		{
			if (MashState[i].Instigator == Instigator)
			{
				MashRate = MashState[i].MashRate;
				bIsMashRateSufficient = MashState[i].bIsMashRateSufficient;
				return;
			}
		}

		MashRate = 0.0;
		bIsMashRateSufficient = false;
	}

	bool IsButtonMashActive(FInstigator Instigator)
	{
		for (int i = 0, Count = ActiveMashes.Num(); i < Count; ++i)
		{
			if (ActiveMashes[i].Instigator == Instigator)
				return true;
		}

		return false;
	}

	void SnapButtonMashProgress(FInstigator Instigator, float NewProgress)
	{
		if (!HasControl())
			return;

		if (!IsButtonMashActive(Instigator))
		{
			devError(f"No button mash with instigator {Instigator} is active.");
			return;
		}

		FButtonMashState& State = GetState(Instigator);
		State.CurrentProgress = Math::Clamp(NewProgress, 0.0, 1.0);
	}

	void SetButtonMashGainMultiplier(FInstigator Instigator, float GainMultiplier)
	{
		if (!HasControl())
			return;

		if (!IsButtonMashActive(Instigator))
		{
			devError(f"No button mash with instigator {Instigator} is active.");
			return;
		}

		FButtonMashState& State = GetState(Instigator);
		State.GainMultiplier = GainMultiplier;
	}

	void SetAllowButtonMashCompletion(FInstigator Instigator, bool bAllowCompletion)
	{
		if (!HasControl())
			return;

		if (!IsButtonMashActive(Instigator))
		{
			devError(f"No button mash with instigator {Instigator} is active.");
			return;
		}

		for (int i = 0, Count = ActiveMashes.Num(); i < Count; ++i)
		{
			if (ActiveMashes[i].Instigator == Instigator
				&& ActiveMashes[i].IsDoubleMash())
			{
				devError("Cannot use SetAllowButtonMashCompletion on a double button mash - this would not be network-safe.");
				return;
			}
		}

		FButtonMashState& State = GetState(Instigator);
		State.bAllowCompletion = bAllowCompletion;
	}

	FButtonMashState& GetState(FInstigator Instigator, float DefaultProgress = 0.0)
	{
		for (int i = 0, Count = MashState.Num(); i < Count; ++i)
		{
			if (MashState[i].Instigator == Instigator)
				return MashState[i];
		}

		FButtonMashState State;
		State.Instigator = Instigator;
		State.CurrentProgress = DefaultProgress;
		MashState.Add(State);

		return MashState.Last();
	}

	void ClearState(FInstigator Instigator)
	{
		for (int i = 0, Count = MashState.Num(); i < Count; ++i)
		{
			if (MashState[i].Instigator == Instigator)
			{
				MashState.RemoveAt(i);
				break;
			}
		}
	}
};