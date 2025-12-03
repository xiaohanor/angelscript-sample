struct FMeltdownBossPhaseThreeStoneBeastIdleParams
{
	float Duration;
};

class UMeltdownBossPhaseThreeStoneBeastIdleCapability : UHazeCapability
{
	default CapabilityTags.Add(CapabilityTags::GameplayAction);
	default TickGroup = EHazeTickGroup::Gameplay;

	AMeltdownBossPhaseThreeShootingFlyingStoneBeast StoneBeast;

	float IdleDuration;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		StoneBeast = Cast<AMeltdownBossPhaseThreeShootingFlyingStoneBeast>(Owner);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate(FMeltdownBossPhaseThreeStoneBeastIdleParams& Params) const
	{
		if (StoneBeast.ActionQueue.Start(this, Params))
			return true;
		return false;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (ActiveDuration > IdleDuration)
			return true;
		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FMeltdownBossPhaseThreeStoneBeastIdleParams Params)
	{
		IdleDuration = Params.Duration;
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		StoneBeast.ActionQueue.Finish(this);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
	}
};