class UCoastBossHideBossCapability : UHazeCapability
{
	default CapabilityTags.Add(CapabilityTags::GameplayAction);
	default TickGroup = EHazeTickGroup::Gameplay;
	ACoastBoss CoastBoss;

	bool bEverActivated = false;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		CoastBoss = Cast<ACoastBoss>(Owner);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (bEverActivated)
			return false;
		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{ 
		if (CoastBoss.bStarted) 
			return true;
		if (CoastBoss.GetMovementMode() == ECoastBossMovementMode::LerpIn) 
			return true;
		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		bEverActivated = true;
		CoastBoss.SetActorHiddenInGame(true);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		// we want to move the critter before unhiding 
		if (CoastBoss.GetMovementMode() == ECoastBossMovementMode::LerpIn) 
			Timer::SetTimer(this, n"DelayedUnhide", 0.5);
		else
			CoastBoss.SetActorHiddenInGame(false);
	}

	UFUNCTION()
	void DelayedUnhide()
	{
		if (IsValid(CoastBoss))
			CoastBoss.SetActorHiddenInGame(false);
	}
};