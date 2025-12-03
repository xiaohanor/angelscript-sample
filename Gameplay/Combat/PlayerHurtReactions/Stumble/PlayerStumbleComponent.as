struct FStumble
{
	UPROPERTY()
	FVector Move = FVector::ZeroVector;

	UPROPERTY()
	float Duration = 1.0;

	UPROPERTY()
	FName FeatureTag = n"Stumble";

	UPROPERTY()
	float Cooldown = 0.0;

	float Time;

	FStumble(FVector StumbleMove, float StumbleDuration)
	{
		Move = StumbleMove;
		Duration = StumbleDuration;
	}

	bool IsValid() const
	{
		return (Move != FVector::ZeroVector);
	}
}

struct FStumbleAnimData
{
	EHazeCardinalDirection Direction = EHazeCardinalDirection::Backward;
	float Duration = 1.0;
}

class UPlayerStumbleComponent : UActorComponent
{
	private FStumble Stumble;

	FStumbleAnimData AnimData;

	float LastStumbleTime = -BIG_NUMBER;

	bool HasStumble() const
	{
		return Stumble.IsValid();
	}

	bool HasRecentStumble(float MaxTimeSince) const
	{
		if (!Stumble.IsValid())
			return false;
		if (Time::GetGameTimeSince(Stumble.Time) > MaxTimeSince)
			return false;
		return true;
	}

	void ConsumeStumble(FStumble& OutStumble)
	{
		OutStumble = Stumble;
		Stumble = FStumble();
	}

	void ApplyStumble(FStumble _Stumble)
	{
#if TEST
		devCheck(!_Stumble.Move.IsZero(), "Applied stumble with Move being ZeroVector, this is not valid!");
#endif
		Stumble = _Stumble;
		Stumble.Time = Time::GameTimeSeconds;
	}

	void ClearOldStumbles(float OlderThan)
	{
		if (HasStumble() && (Time::GetGameTimeSince(Stumble.Time) > OlderThan))
			Stumble = FStumble();
	}	

	void ClearCooldownStumbles(float LastEndTime)
	{
		if (Time::GameTimeSeconds < LastEndTime + Stumble.Cooldown)
			Stumble = FStumble();
	}
}
