
// Values for output pins
enum EVoxGlobalTimerExecType
{
	Play,
	Blocked
}

// Try to trigger Global VO Trigger with set value. If TimerOverride is 0 default value will be used instead.
UFUNCTION(Category = "HazeVox", meta = (ExpandToEnum = "TimerName", ExpandedEnum = "/Script/Angelscript.GlobalVoTimers", ExpandEnumAsExecs = "OutResult"))
void GlobalVoTimerTrigger(FName TimerName, float TimerOverride, EVoxGlobalTimerExecType& out OutResult)
{
	auto VoTimersComponent = UGlobalVoTimersPlayerComponent::GetOrCreate(Game::GetMio());
	// Check if timer triggerd
	bool bTriggered = VoTimersComponent.TriggerTimer(TimerName, TimerOverride);

	// Set value to decide what output pin to use
	if (bTriggered)
		OutResult = EVoxGlobalTimerExecType::Play;
	else
		OutResult = EVoxGlobalTimerExecType::Blocked;
}

// Check if Global VO Timer is currently active
UFUNCTION(Category = "HazeVox", meta = (ExpandToEnum = "TimerName", ExpandedEnum = "/Script/Angelscript.GlobalVoTimers", ExpandEnumAsExecs = "OutResult"))
void GlobalVoTimerCheck(FName TimerName, EVoxGlobalTimerExecType& out OutResult)
{
	auto VoTimersComponent = UGlobalVoTimersPlayerComponent::GetOrCreate(Game::GetMio());
	// Check if timer triggerd
	const bool bTimerActive = VoTimersComponent.IsTimerActive(TimerName);

	// Set value to decide what output pin to use
	if (bTimerActive)
		OutResult = EVoxGlobalTimerExecType::Blocked;
	else
		OutResult = EVoxGlobalTimerExecType::Play;
}

// Reset Global VO Timer
UFUNCTION(Category = "HazeVox", meta = (ExpandToEnum = "TimerName", ExpandedEnum = "/Script/Angelscript.GlobalVoTimers"))
void GlobalVoTimerReset(FName TimerName)
{
	auto VoTimersComponent = UGlobalVoTimersPlayerComponent::GetOrCreate(Game::GetMio());
	VoTimersComponent.ResetTimer(TimerName);
}

class UGlobalVoTimersPlayerComponent : UActorComponent
{
	const float GlobalDefaultTimerValue = 10.0;

	// Default timer names are added in DefaultHazeTags.ini
	TMap<FName, float> DefaultTimerValues;
	default DefaultTimerValues.Add(n"Combat", 3.0);
	default DefaultTimerValues.Add(n"Reload", 3.0);
	default DefaultTimerValues.Add(n"VO_InGameTimer_1", 2.0);

	TMap<FName, float> Timers;

	bool TriggerTimer(FName TimerName, float TimerOverride = 0.0)
	{
#if EDITOR
		if (VoxDebug::IsVoDesigner() && TimerName.IsNone())
			devError("TimerName missing for Global VO Timer Timer");
#endif

		const float GameTimeNow = Time::GameTimeSeconds;

		// Get current timer or create one that isn't set
		float TimerValue = Timers.FindOrAdd(TimerName, 0.0);

		if (TimerValue > GameTimeNow)
		{
			// If timer is in the future do nothing
			return false;
		}
		else
		{
			// If timer is in the past and we have override use that
			if (TimerOverride > 0.001)
			{
				Timers[TimerName] = GameTimeNow + TimerOverride;
			}
			else
			{
				// Use value from default timers if we have one, otherwise use global default
				float NewTimerTime;
				bool bFoundDefault = DefaultTimerValues.Find(TimerName, NewTimerTime);
				if (!bFoundDefault)
					NewTimerTime = GlobalDefaultTimerValue;

				Timers[TimerName] = GameTimeNow + NewTimerTime;
			}
			return true;
		}
	}

	void ResetTimer(FName TimerName)
	{
#if EDITOR
		if (VoxDebug::IsVoDesigner() && TimerName.IsNone())
			devError("TimerName missing for Global VO Timer Timer");
#endif

		if (Timers.Contains(TimerName))
		{
			Timers[TimerName] = 0.0;
		}
	}

	bool IsTimerActive(FName TimerName) const
	{
#if EDITOR
		if (VoxDebug::IsVoDesigner() && TimerName.IsNone())
			devError("TimerName missing for Global VO Timer Check");
#endif

		const float GameTimeNow = Time::GameTimeSeconds;

		float TimerValue = 0.0;
		const bool bFoundTimer = Timers.Find(TimerName, TimerValue);
		if (bFoundTimer && TimerValue > GameTimeNow)
		{
			return true;
		}

		return false;
	}

#if TEST
	void DebugTemporalLog()
	{
		const float GameTimeNow = Time::GameTimeSeconds;
		bool bActive = false;

		for (const auto& Timer : Timers)
		{
			const float TimerTime = Math::Max(Timer.Value - GameTimeNow, 0.0);
			if (TimerTime > 0.0)
				bActive = true;

			TEMPORAL_LOG("Vox/VoTimers").Value(Timer.Key.ToString(), TimerTime);
		}

		if (bActive)
			TEMPORAL_LOG("Vox/VoTimers").CustomStatus("Status", "Active", FLinearColor::Green);
		else
			TEMPORAL_LOG("Vox/VoTimers").CustomStatus("Status", "Idle", FLinearColor::White);
	}
#endif
}
