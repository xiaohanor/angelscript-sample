
enum EGlobalVoRateLimitExecType
{
	Play,
	Blocked
}

struct FGlobalVoRateLimit
{
	FName LimitName;
	TArray<float> Times;
}

UFUNCTION(Category = "HazeVox")
void GlobalVoRateLimitEvent(FName LimitName)
{
	auto LimitComponent = UGlobalVoRateLimitPlayerComponent::GetOrCreate(Game::GetMio());
	LimitComponent.AddLimitEvent(LimitName);
}

UFUNCTION(Category = "HazeVox", meta = (ExpandEnumAsExecs = "OutResult"))
void GlobalVoRateLimitCheck(FName LimitName, EGlobalVoRateLimitExecType& out OutResult, float TimeWindow = 10.0, int NumEventsLimit = 5)
{
	auto LimitComponent = UGlobalVoRateLimitPlayerComponent::GetOrCreate(Game::GetMio());
	bool bRateLimited = LimitComponent.IsRateLimited(LimitName, TimeWindow, NumEventsLimit);

	if (bRateLimited)
		OutResult = EGlobalVoRateLimitExecType::Play;
	else
		OutResult = EGlobalVoRateLimitExecType::Blocked;
}

class UGlobalVoRateLimitPlayerComponent : UActorComponent
{
	TArray<FGlobalVoRateLimit> Limits;

	void AddLimitEvent(FName LimitName)
	{
		if (VoxDebug::IsVoDesigner() && LimitName.IsNone())
			devError("LimitName missing for Global VO Limit Event");

		for (auto& Limit : Limits)
		{
			if (Limit.LimitName == LimitName)
			{
				Limit.Times.Add(Time::GameTimeSeconds);

				while (Limit.Times.Num() > 50)
				{
					Limit.Times.RemoveAt(0);
				}

				return;
			}
		}

		FGlobalVoRateLimit NewLimit;
		NewLimit.LimitName = LimitName;
		NewLimit.Times.Add(Time::GameTimeSeconds);
		Limits.Add(NewLimit);
	}

	bool IsRateLimited(FName LimitName, float Duration, int RateLimit) const
	{
		if (VoxDebug::IsVoDesigner() && LimitName.IsNone())
			devError("LimitName missing for Global VO Limit Is Limited");

		const int NumEvents = GetNumEvents(LimitName, Duration);

		const bool bLimited = NumEvents <= RateLimit;
		return bLimited;
	}

	int GetNumEvents(FName LimitName, float Duration) const
	{
		if (VoxDebug::IsVoDesigner() && LimitName.IsNone())
			devError("TimerName missing for Global VO Limit Num Events");

		const float GameTimeNow = Time::GameTimeSeconds;
		const float GameTimeLimit = GameTimeNow - Duration;

		for (auto& Limit : Limits)
		{
			if (Limit.LimitName == LimitName)
			{
				int NumEvents = 0;
				for (int i = Limit.Times.Num() - 1; i >= 0; --i)
				{
					if (Limit.Times[i] < GameTimeLimit)
						break;

					NumEvents++;
				}
				return NumEvents;
			}
		}

		return -1;
	}

#if TEST
	void DebugTemporalLog() const
	{
		const float GameTimeNow = Time::GameTimeSeconds;
		bool bActive = false;

		for (auto Limit : Limits)
		{
			int Num5s = 0;
			int Num10s = 0;
			int Num20s = 0;
			int Num30s = 0;

			for (float Time : Limit.Times)
			{
				const float TimeAge = GameTimeNow - Time;
				if (TimeAge <= 5.0)
					Num5s++;
				else if (TimeAge <= 10.0)
					Num10s++;
				else if (TimeAge <= 20.0)
					Num20s++;
				else if (TimeAge <= 30.0)
					Num30s++;
			}

			if (Num5s + Num10s + Num20s + Num30s > 0)
				bActive = true;

			TEMPORAL_LOG("Vox/VoRateLimits").Value(f"{Limit.LimitName};0-5 seconds", Num5s);
			TEMPORAL_LOG("Vox/VoRateLimits").Value(f"{Limit.LimitName};5-10 seconds", Num10s);
			TEMPORAL_LOG("Vox/VoRateLimits").Value(f"{Limit.LimitName};10-20 seconds", Num20s);
			TEMPORAL_LOG("Vox/VoRateLimits").Value(f"{Limit.LimitName};20-30 seconds", Num30s);
		}

		if (bActive)
			TEMPORAL_LOG("Vox/VoRateLimits").CustomStatus("Status", "Active", FLinearColor::Green);
		else
			TEMPORAL_LOG("Vox/VoRateLimits").CustomStatus("Status", "Idle", FLinearColor::White);
	}
#endif
}
