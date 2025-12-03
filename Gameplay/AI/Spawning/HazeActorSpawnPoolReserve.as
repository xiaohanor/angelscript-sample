namespace HazeActorSpawnPoolReserve
{
	UHazeActorSpawnPoolReserve Create(UObject Owner)
	{
		if (Owner == nullptr)
			return nullptr;

		UHazeActorSpawnPoolReserve Reserve = NewObject(Owner, UHazeActorSpawnPoolReserve, bTransient = true);
		Reserve.MakeNetworked(Owner);
		return Reserve;
	}
}

class UHazeActorSpawnPoolReserve : UObject
{
	private TArray<AHazeActor> ReservedActors;

	void ReserveSpawn(UHazeActorNetworkedSpawnPoolComponent SpawnPool, int NumberOfReservedActors = 1)
	{
		if (SpawnPool == nullptr)
			return;
		SpawnPool.OnSpawnedBySpawner.FindOrAdd(this).AddUFunction(this, n"OnSpawned");	
		SpawnPool.SpawnBatchControl(FHazeActorSpawnParameters(this), NumberOfReservedActors);
	}

	UFUNCTION()
	private void OnSpawned(AHazeActor SpawnedActor, FHazeActorSpawnParameters Params)
	{
		// Disable reserved actor until we want to use it
		SpawnedActor.AddActorDisable(this);
		ReservedActors.Add(SpawnedActor);
	}

	AHazeActor Spawn()
	{
		if (!ensure(ReservedActors.Num() > 0))
			return nullptr;

		// Use first reserved actor
		AHazeActor ReservedActor = ReservedActors[0];
		ReservedActors.RemoveAt(0); 
		ReservedActor.RemoveActorDisable(this);
		return ReservedActor;
	}
}

