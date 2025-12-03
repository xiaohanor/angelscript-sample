struct FKnockdown
{
	UPROPERTY()
	FVector Move = FVector::ZeroVector;

	UPROPERTY()
	float Duration = 3.0;

	UPROPERTY()
	float StandUpDuration = 1.0;

	UPROPERTY()
	float PostKnockedFriction = 4.0;

	UPROPERTY()
	float AirFriction = 0.1;

	UPROPERTY()
	bool bInvertDirection = false;

	UPROPERTY()
	FName FeatureTag = n"Knockdown";

	UPROPERTY()
	float Cooldown = 0.0;

	float Time;

	FKnockdown(FVector _Move, float _Duration)
	{
		Move = _Move;
		Duration = _Duration;
	}

	bool IsValid() const
	{
		return (Move != FVector::ZeroVector);
	}
}

struct FKnockDownAnimData
{
	EHazeCardinalDirection Direction = EHazeCardinalDirection::Backward;
	float StartKnockdownDuration = 3.0;
	float StandUpDuration = 1.0;
	bool bStandUp = false;
}

class UPlayerKnockdownComponent : UActorComponent
{
	private FKnockdown Knockdown;

	FKnockDownAnimData AnimData;

	access PlayerKnockdownCapability = private, UPlayerKnockdownCapability;
	access : PlayerKnockdownCapability bool bPlayerKnockedDown;

	bool HasKnockdown() const
	{
		return Knockdown.IsValid();
	}

	bool HasRecentKnockdown(float MaxTimeSince) const
	{
		if (!Knockdown.IsValid())
			return false;
		if (Time::GetGameTimeSince(Knockdown.Time) > MaxTimeSince)
			return false;
		return true;
	}
	
	void ConsumeKnockdown(FKnockdown& OutKnockdown)
	{
		OutKnockdown = Knockdown;
		Knockdown = FKnockdown();
	}

	void ApplyKnockdown(FKnockdown _Knockdown)
	{
#if TEST
		devCheck(!_Knockdown.Move.IsZero(), "Applied knockdown with Move being ZeroVector, this is not valid!");
#endif
		Knockdown = _Knockdown;
		if (Knockdown.Move.IsZero())
			Knockdown.Move = -Owner.ActorForwardVector; // Fall backwards if force is bad.
		Knockdown.Time = Time::GameTimeSeconds;
	}

	void ClearOldKnockdowns(float OlderThan)
	{
		if (HasKnockdown() && (Time::GetGameTimeSince(Knockdown.Time) > OlderThan))
			Knockdown = FKnockdown();
	}

	UFUNCTION()
	bool IsPlayerKnockedDown() const
	{
		return bPlayerKnockedDown;
	}

	void ClearCooldownKnockdowns(float LastEndTime)
	{
		if (Time::GameTimeSeconds < LastEndTime + Knockdown.Cooldown)
			Knockdown = FKnockdown();
	}
}
