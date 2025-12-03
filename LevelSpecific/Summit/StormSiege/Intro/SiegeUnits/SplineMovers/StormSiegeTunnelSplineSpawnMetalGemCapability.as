class UStormSiegeTunnelSplineSpawnMetalGemCapability : UHazeCapability
{
	default CapabilityTags.Add(CapabilityTags::GameplayAction);

	default TickGroup = EHazeTickGroup::Gameplay;

	default CapabilityTags.Add(CapabilityTags::GameplayAction);

	default TickGroup = EHazeTickGroup::Gameplay;

	AStormSiegeTunnelSplineEnemyManager EnemyManager;

	float SpawnRate = 1.0;
	float SpawnTime;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		EnemyManager = Cast<AStormSiegeTunnelSplineEnemyManager>(Owner);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (!EnemyManager.bIsSpawnActive)
			return false;

		if (!EnemyManager.bIsFinalPhase)
			return false;

		if (!EnemyManager.CanSpawnMetalGem())
			return false;
		
		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (!EnemyManager.bIsSpawnActive)
			return true;

		if (!EnemyManager.bIsFinalPhase)
			return true;

		if (!EnemyManager.CanSpawnMetalGem())
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		SpawnTime = SpawnRate;
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		SpawnTime -= DeltaTime;

		if (SpawnTime < 0.0)
		{
			SpawnTime = SpawnRate;
			EnemyManager.SpawnMetalGem();
		}
	}
};