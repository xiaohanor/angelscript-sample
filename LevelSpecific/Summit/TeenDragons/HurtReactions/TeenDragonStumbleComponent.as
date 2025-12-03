struct FTeenDragonStumble
{
	FVector Move = FVector::ZeroVector;
	float ArcHeight = 0.0;
	float Duration = 1.0;
	FName FeatureTag = n"DragonStumble";
	float Time;

	FTeenDragonStumble(FVector StumbleMove, float StumbleDuration)
	{
		Move = StumbleMove;
		Duration = StumbleDuration;
	}

	bool IsValid() const
	{
		return (Move != FVector::ZeroVector);
	}

	void Apply(AHazeActor Target)
	{
		UTeenDragonStumbleComponent StumbleComp = UTeenDragonStumbleComponent::Get(Target);		
		if ((StumbleComp != nullptr) && !StumbleComp.HasRecentStumble(0.1))
			StumbleComp.ApplyStumble(this);
	}
}

struct FTeenDragonStumbleAnimData
{
	EHazeCardinalDirection Direction = EHazeCardinalDirection::Backward;
	float Duration = 1.0;
}

class UTeenDragonStumbleComponent : UActorComponent
{
	private FTeenDragonStumble Stumble;

	FTeenDragonStumbleAnimData AnimData;

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

	void ConsumeStumble(FTeenDragonStumble& OutStumble)
	{
		OutStumble = Stumble;
		Stumble = FTeenDragonStumble();
	}

	void ApplyStumble(FTeenDragonStumble _Stumble)
	{
		Stumble = _Stumble;
		Stumble.Time = Time::GameTimeSeconds;
	}

	void ClearOldStumbles(float OlderThan)
	{
		if (HasStumble() && (Time::GetGameTimeSince(Stumble.Time) > OlderThan))
			Stumble = FTeenDragonStumble();
	}	
};