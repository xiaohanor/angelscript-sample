class UIslandArenaRespawnPointsCapability : UHazeCapability
{
	default CapabilityTags.Add(n"PlayerRespawning");

	default TickGroup = EHazeTickGroup::AfterGameplay;
	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;

	AIslandArenaRespawnPointsManager RespawnManager;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		RespawnManager = Cast<AIslandArenaRespawnPointsManager>(Owner);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (!RespawnManager.bIsActive)
			return false;
		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (!RespawnManager.bIsActive)
			return true;
		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		EnableAllRespawnPoints();
		for (AHazePlayerCharacter Player : Game::Players)
		{
			UPlayerRespawnComponent RespawnComp = UPlayerRespawnComponent::Get(Player);
			RespawnComp.ApplyRespawnOverrideDelegate(this, FOnRespawnOverride(this, n"HandleRespawn"), EInstigatePriority::High);
		}
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		DisbleAllRespawnPoints(this);
		for (AHazePlayerCharacter Player : Game::Players)
		{
			Player.ClearRespawnPointOverride(this);
		}
	}
	
	UFUNCTION()
	private bool HandleRespawn(AHazePlayerCharacter Player, FRespawnLocation& OutLocation)
	{
		OutLocation.RespawnPoint = GetBestRespawnPoint(Player);
		if (OutLocation.RespawnPoint == nullptr)
			return false;
		OutLocation.RespawnTransform = OutLocation.RespawnPoint.GetPositionForPlayer(Player);

#if EDITOR
		RespawnManager.LastUsedRespawnPoint = OutLocation.RespawnPoint;
		RespawnManager.LastUsedTimer = 2.0;
#endif
		return true;
	}

	void EnableAllRespawnPoints()
	{
		for (ARespawnPoint RespawnPoint : RespawnManager.RespawnPoints)		
		{
			RespawnPoint.EnableForPlayer(Game::Mio, this);
			RespawnPoint.EnableForPlayer(Game::Zoe, this);
		}
	}

	void DisbleAllRespawnPoints(UIslandArenaRespawnPointsCapability IslandArenaRespawnPointsCapability)
	{
		for (ARespawnPoint RespawnPoint : RespawnManager.RespawnPoints)		
		{
			RespawnPoint.DisableForPlayer(Game::Mio, this);
			RespawnPoint.DisableForPlayer(Game::Zoe, this);
		}
	}

	// Use closest safe respawn point
	ARespawnPoint GetBestRespawnPoint(AHazePlayerCharacter Player)
	{
		ARespawnPoint BestPoint = nullptr;	
		ARespawnPoint BestBackupPoint = nullptr;	

		TArray<AHazeActor> SpawnedActors;
		for (AHazeActorSpawnerBase Spawner : RespawnManager.Spawners)
		{
			UHazeTeam Team = Spawner.SpawnerComp.GetSpawnedActorsTeam();
			if (Team == nullptr)
				continue;
			TArray<AHazeActor> Members = Team.GetMembers();
			SpawnedActors.Append(Members);
		}

		float MinDistSqr = BIG_NUMBER;
		float MinBackupPointDistSqr = BIG_NUMBER;
		for (ARespawnPoint Point : RespawnManager.RespawnPoints)
		{
			for (AHazeActor Actor : SpawnedActors)
			{
				float DistSqr = Player.ActorLocation.DistSquared2D(Point.ActorLocation);
			
				// If no safe space is found.
				if (DistSqr < MinBackupPointDistSqr)
				{
					MinBackupPointDistSqr = DistSqr;
					BestBackupPoint = Point;
				}

				// Danger zone
				float ActorDistSqr = Actor.ActorLocation.DistSquared2D(Point.ActorLocation);
				if (ActorDistSqr < Math::Square(RespawnManager.RespawnSafeDistance))
					continue;

				if (DistSqr > MinDistSqr)
					continue;
				
				// Good respawn point
				MinDistSqr = DistSqr;
				BestPoint = Point;
			}			
		}

		// There is no safe space, take closest
		if (BestPoint == nullptr)
		{
			BestPoint = BestBackupPoint;
		}

		return BestPoint;
	}

};