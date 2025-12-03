class USketchbookBossDropProjectilesCapability : USketchbookBossChildCapability
{
	default CapabilityTags.Add(CapabilityTags::GameplayAction);

	float LastProjectileSpawnTime;

	
	USketchbookDuckBossComponent DuckComp;


	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Super::Setup();
		DuckComp = USketchbookDuckBossComponent::Get(Owner);
	}


	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if(!DuckComp.bCanDropEgg)
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if(!DuckComp.bCanDropEgg)
			return true;

		return false;
	}


	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if(Time::GetGameTimeSince(LastProjectileSpawnTime) >= DuckComp.TimeBetweenEggs)
			SpawnProjectile();
	}

	void SpawnProjectile()
	{
		LastProjectileSpawnTime = Time::GameTimeSeconds;
		SpawnActor(Boss.ProjectileClass, Boss.ProjectileSpawnPoint.WorldLocation, Boss.ProjectileSpawnPoint.WorldRotation);
	
		Boss.Mesh.SetAnimTrigger(n"DropProjectile");
	}
};