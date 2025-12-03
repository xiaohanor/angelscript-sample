// Exactly the same as the normal HazeActorSpawnerCapbility, except it is always controlled by Zoe.
class USummitDecimatorTopdownZoeControlledSpawnerCapability : UHazeCapability
{
	default TickGroup = EHazeTickGroup::AfterGameplay;

	UHazeActorSpawnerComponent SpawnerComp;
	TArray<UHazeActorSpawnPattern> SpawnPatterns;
	bool bNeedsUpdate = true; 

	TMap<TSubclassOf<AHazeActor>, UHazeActorNetworkedSpawnPoolComponent> SpawnPools;
	TMap<AHazeActor, UHazeActorSpawnPattern> SpawningPatterns;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Owner.SetActorControlSide(Game::Zoe);
		SpawnerComp = UHazeActorSpawnerComponent::Get(Owner);
		
		// Sort spawn patterns in ascending order
		Owner.GetComponentsByClass(SpawnPatterns);
		SpawnerComp.SortSpawnPatterns(SpawnPatterns);

		for (UHazeActorSpawnPattern Pattern : SpawnPatterns)
		{	
			TArray<TSubclassOf<AHazeActor>> SpawnClasses;
			Pattern.GetSpawnClasses(SpawnClasses);
			Pattern.OnActivated.AddUFunction(this, n"OnPatternActivated");
	
			for (TSubclassOf<AHazeActor> SpawnClass : SpawnClasses)
			{
				if (!SpawnClass.IsValid())
					continue;
				UHazeActorNetworkedSpawnPoolComponent SpawnPool = HazeActorNetworkedSpawnPoolStatics::GetOrCreateSpawnPool(SpawnClass, Owner);
				SpawnPool.OnSpawnedBySpawner.FindOrAdd(Pattern).AddUFunction(this, n"OnSpawnedActor");
				SpawnPools.Add(SpawnClass, SpawnPool);
			}
		}		

		SpawnerComp.OnResetSpawnPatterns.AddUFunction(this, n"OnResetSpawnPatterns");
	}

	UFUNCTION()
	private void OnResetSpawnPatterns(UHazeActorSpawnerComponent Spawner)
	{
		bNeedsUpdate = true;
	}

	UFUNCTION()
	private void OnPatternActivated(UHazeActorSpawnPattern Pattern)
	{
		if(Pattern.NeedsUpdate())
			bNeedsUpdate = true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (!HasControl()) // Control side tick only
			return false;
		if (!SpawnerComp.IsSpawnerActive())
			return false;
		if (SpawnPatterns.Num() == 0)
			return false;
		if (!bNeedsUpdate)
			return false;
		
		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (!SpawnerComp.IsSpawnerActive())
			return true;
		if (!bNeedsUpdate)
			return true;
		return false;
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		bNeedsUpdate = false;
		FHazeActorSpawnBatch SpawnBatch;
		for (UHazeActorSpawnPattern Pattern : SpawnPatterns)
		{
			if (!Pattern.IsActivePattern())
				continue;
			if (Pattern.NeedsUpdate())
				bNeedsUpdate = true;		
			if (Pattern.IsCompleted())
				continue;

			Pattern.UpdateControlSide(DeltaTime, SpawnBatch);
		}

		for (auto SpawnEntry : SpawnBatch.Batch)
		{
			if (!SpawnEntry.Key.IsValid())
				continue;
			if (!ensure(SpawnPools.Contains(SpawnEntry.Key)))
				continue;
			// for (FHazeActorSpawnParameters SpawnParams : SpawnEntry.Value.SpawnParameters)
			// {
			// 	SpawnPools[SpawnEntry.Key].Spawn(SpawnParams);
			// }
			SpawnPools[SpawnEntry.Key].SpawnBatchControl(SpawnEntry.Value.SpawnParameters);
		}		
	}

	// This will get called on both sides immediately after spawnpool has spawned 
	UFUNCTION(NotBlueprintCallable)
	private void OnSpawnedActor(AHazeActor SpawnedActor, FHazeActorSpawnParameters Params)
	{
		UHazeActorSpawnPattern SpawnPattern = Cast<UHazeActorSpawnPattern>(Params.Spawner);
		if (SpawnPattern == nullptr)
			return;

		if (!ensure(SpawnPatterns.Contains(SpawnPattern)))
			return;
		
		// Keep track of what pattern spawned this actor
		SpawningPatterns.Add(SpawnedActor, SpawnPattern);

		SpawnedActor.JoinTeam(SpawnerComp.TeamName);

		// Let respawn component know on both sides that it has been spawned 
		UHazeActorRespawnableComponent RespawnComp = UHazeActorRespawnableComponent::GetOrCreate(SpawnedActor);
		RespawnComp.OnSpawned(Owner, Params);

		// This will tell us when actor is killed or otherwise remove from play
		RespawnComp.OnUnspawn.AddUFunction(this, n"OnUnspawnedActor");

		// Let spawn pattern know that spawn was completed
		SpawnPattern.OnSpawn(SpawnedActor);

		// Let any other interested parties know spawn was completed
		SpawnerComp.OnPostSpawn.Broadcast(SpawnedActor, SpawnerComp, SpawnPattern);

		RespawnComp.OnPostSpawned();

		SpawnedActor.SetActorControlSide(Game::Zoe);
	}

	// This is called on both sides when spawned actor dies or is otherwise available for respawn.
	UFUNCTION()
	private void OnUnspawnedActor(AHazeActor UnspawnedActor)
	{
		UnspawnedActor.LeaveTeam(SpawnerComp.TeamName);

		UHazeActorRespawnableComponent RespawnComp = UHazeActorRespawnableComponent::Get(UnspawnedActor);
		RespawnComp.OnUnspawn.Unbind(this, n"OnUnspawnedActor");

		// Let spawn pool know actor can be respawned
		if (ensure(SpawnPools.Contains(UnspawnedActor.Class)))
			SpawnPools[UnspawnedActor.Class].UnSpawn(UnspawnedActor);

		// Notify spawn pattern
		UHazeActorSpawnPattern SpawnPattern = nullptr;
		if (ensure(SpawningPatterns.Contains(UnspawnedActor)))
		{
			SpawnPattern = SpawningPatterns[UnspawnedActor];
			SpawnPattern.OnUnspawn(UnspawnedActor);
		}
			
		SpawnerComp.OnPostUnspawn.Broadcast(UnspawnedActor, SpawnerComp, SpawnPattern);
	}
}
