class UIslandWalkerDyadSpawnerCapability : UHazeCapability
{
	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;
	default CapabilityTags.Add(BasicAITags::CompoundBehaviour);

	UIslandWalkerSettings WalkerSettings;
	UHazeActorSpawnerComponent SpawnerComp;
	UHazeActorSpawnPatternInterval RedSpawnPattern;
	UHazeActorSpawnPatternInterval BlueSpawnPattern;
	UBasicAIHealthComponent HealthComp;
	UIslandWalkerLegsComponent LegsComp;
	UIslandWalkerSpawnerComponent WalkerSpawnerComp;
	UIslandWalkerComponent SuspendComp;
	UIslandWalkerPhaseComponent PhaseComp;

	TArray<UWalkerSpawnPointComponent> SpawnPoints;
	int SpawnIndex;
	
	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		AAIIslandWalker Walker = Cast<AAIIslandWalker>(Owner);
		WalkerSettings = UIslandWalkerSettings::GetSettings(Owner);
		HealthComp = UBasicAIHealthComponent::Get(Owner);
		SpawnerComp = UHazeActorSpawnerComponent::Get(Owner);
		SpawnerComp.OnPostSpawn.AddUFunction(this, n"OnPostSpawn");

		Owner.GetComponentsByClass(SpawnPoints);

		WalkerSpawnerComp = UIslandWalkerSpawnerComponent::GetOrCreate(Owner);

		SuspendComp = UIslandWalkerComponent::GetOrCreate(Owner);
		PhaseComp = UIslandWalkerPhaseComponent::GetOrCreate(Owner);
	}

	UFUNCTION()
	private void OnPostSpawn(AHazeActor SpawnedActor, UHazeActorSpawnerComponent Spawner,
	                         UHazeActorSpawnPattern SpawningPattern)
	{
		UWalkerSpawnPointComponent Point = SpawnPoints[SpawnIndex];
		SpawnedActor.SetActorLocation(Point.WorldLocation);
		UIslandDyadDeployComponent::GetOrCreate(SpawnedActor).DeployDirection = Point.ForwardVector;
		
		SpawnIndex++;
		if(SpawnIndex >= SpawnPoints.Num())
			SpawnIndex = 0;

		UIslandWalkerEffectHandler::Trigger_OnSpawnedMinion(Owner, FIslandWalkerSpawnedMinionEventData(Point.WorldLocation, Point.ForwardVector));
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if(HealthComp.IsDead())
			return false;
		if(!SuspendComp.bSpawning)
			return false;
		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if(HealthComp.IsDead())
			return true;
		if(!SuspendComp.bSpawning)
			return true;
		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		SpawnIndex = 0;	
		RedSpawnPattern.ActivatePattern(this);
		BlueSpawnPattern.ActivatePattern(this);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		RedSpawnPattern.DeactivatePattern(this);
		BlueSpawnPattern.DeactivatePattern(this);
	}
}