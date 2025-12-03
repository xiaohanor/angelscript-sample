class ASerpentBossAttackPrototypeManager : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

#if EDITOR
	UPROPERTY(DefaultComponent, Attach = Root)
	UBillboardComponent Visual;
	default Visual.SetWorldScale3D(FVector(20.0));
#endif

	UPROPERTY(DefaultComponent)
	UHazeCapabilityComponent CapabilityComp;
	default CapabilityComp.DefaultCapabilities.Add(n"StoneDragonTestHomingMissilesCapability");
	default CapabilityComp.DefaultCapabilities.Add(n"StoneDragonTestProximitySpellCapability");

	UPROPERTY(EditAnywhere)
	TSubclassOf<ASerpentHomingMissileSpawner> HomingMissileSpawnerClass;

	UPROPERTY(EditAnywhere)
	TSubclassOf<AStoneBossProximitySpell> ProximitySpellSpawnerClass;
	
	bool bAttacksActive;

	UFUNCTION()
	void ActivateAttacks()
	{
		bAttacksActive = true;
	}

	void SpawnHomingMissilesAttack(FVector Location, AHazePlayerCharacter TargetPlayer)
	{
		ASerpentHomingMissileSpawner Spawner = SpawnActor(HomingMissileSpawnerClass, Location, bDeferredSpawn = true);
		Spawner.TargetPlayer = TargetPlayer;
		Spawner.MissileTargetSpeed = 5000.0;
		Spawner.TEMPDebugSphereRadius = 300.0;
		Spawner.bShowDebug = false;
		Spawner.SpawnRate = 0.15;
		Spawner.AttachToActor(this, NAME_None, EAttachmentRule::KeepWorld);
		FinishSpawningActor(Spawner);
	}

	void SpawnProximitySpell(FVector Location)
	{
		AStoneBossProximitySpell Prxomity = SpawnActor(ProximitySpellSpawnerClass, Location, bDeferredSpawn = true);
		Prxomity.AttachToActor(this, NAME_None, EAttachmentRule::KeepWorld);
		FinishSpawningActor(Prxomity);	
	}
}