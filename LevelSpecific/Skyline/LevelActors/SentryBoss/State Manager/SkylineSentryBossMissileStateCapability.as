class USkylineSentryBossMissileStateCapability : UHazeCapability
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
		if(Boss.BossState == EBossState::DefenseSystem4)
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{

		if(Boss.BossState == EBossState::DefenseSystem4)
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		TArray<ASkylineSentryBossTile> UnactivatedTiles;
		for(ASkylineSentryBossTile Tile : Boss.Tiles)
		{
			UnactivatedTiles.Add(Tile);
		}

		for(int i = 0; i < TileManager.TilesToSpawnMissileTurrets; i++)
		{

			int Index = Math::RandRange(0, UnactivatedTiles.Num() - 1);

			UnactivatedTiles[Index].SpawnMissileTurret();
			UnactivatedTiles.RemoveAt(Index);
		}
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		for(ASkylineSentryBossMissileTurret Turrets : Boss.ActiveMissileTurrets)
		{
			Turrets.DestroyActor();
		}

	}




};