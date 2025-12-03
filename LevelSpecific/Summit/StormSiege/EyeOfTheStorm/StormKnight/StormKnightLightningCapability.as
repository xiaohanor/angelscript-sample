class UStormKnightLightningCapability : UHazeCapability
{
	default CapabilityTags.Add(n"StormKnightLightningCapability");
	
	default TickGroup = EHazeTickGroup::Gameplay;
	default TickGroupOrder = 100;

	AStormKnight StormKnight;
	UStormKnightSettings StormKnightSettings;
	int SpawnCount;
	float NextSpawnTime;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		StormKnight = Cast<AStormKnight>(Owner);
		StormKnightSettings = UStormKnightSettings::GetSettings(Owner);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (StormKnight.Disablers.Num() > 0)
			return false;

		if (StormKnight.GetDistanceTo(StormKnight.GetClosestPlayer()) > StormKnightSettings.MinAttackDistance)
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (StormKnight.Disablers.Num() > 0)
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		SpawnCount = 0;
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if (Time::GameTimeSeconds > NextSpawnTime)
		{
			NextSpawnTime = Time::GameTimeSeconds + StormKnightSettings.AttackRate;
			StormKnight.SpawnLightningAttack();
			SpawnCount++;
		}
	}

	AHazePlayerCharacter GetClosestPlayer()
	{
		return Game::Mio.GetDistanceTo(StormKnight) < Game::Zoe.GetDistanceTo(StormKnight) ? Game::Mio : Game::Zoe; 
	}
}