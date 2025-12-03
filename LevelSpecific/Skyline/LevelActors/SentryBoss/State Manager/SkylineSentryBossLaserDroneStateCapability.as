class USkylineSentryBossLaserDroneStateCapability : UHazeCapability
{
	default CapabilityTags.Add(CapabilityTags::GameplayAction);

	default TickGroup = EHazeTickGroup::Gameplay;


	ASKylineSentryBoss Boss;
	USkylineSentryBossTileManagerComponent TileManager;
	float TimeToActivateTile;



	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Boss = Cast<ASKylineSentryBoss>(Owner);
		TileManager = USkylineSentryBossTileManagerComponent::Get(Boss);

	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if(Boss.BossState == EBossState::DefenseSystem2)
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if(Boss.BossState == EBossState::DefenseSystem2)
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		TimeToActivateTile = Time::GameTimeSeconds + TileManager.SpawnLaserDronesCooldown;

	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		for(ASkylineSentryBossLaserDrone Drone : Boss.ActiveLaserDrones)
		{
			Drone.DestroyActor();
		}

	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if(TimeToActivateTile > Time::GameTimeSeconds)
			return;


		TArray<ASkylineSentryBossTile> UnactivatedTiles;
		for(ASkylineSentryBossTile Tile : Boss.Tiles)
		{
			UnactivatedTiles.Add(Tile);
		}
		
		for(int i = 0; i < TileManager.TilesToSpawnLaserDrones; i++)
		{
			int Index = Math::RandRange(0, UnactivatedTiles.Num() - 1);

			UnactivatedTiles[Index].SpawnLaserDrone();
			UnactivatedTiles.RemoveAt(Index);
		}
		
		TimeToActivateTile = Time::GameTimeSeconds + TileManager.SpawnLaserDronesCooldown;
	}

};