
event void FRespawnable(AHazeActor RespawnableActor);
event void FRespawnReset();

class UHazeActorRespawnableComponent : UActorComponent
{
    // Triggers when we are available for respawning
	UPROPERTY()
	FRespawnable OnUnspawn;

	// Triggers when we want to reset an actor for reuse
	UPROPERTY()
	FRespawnReset OnRespawn;

	// Triggers immediately after reset
	UPROPERTY()
	FRespawnReset OnPostRespawn;

	FHazeActorSpawnParameters SpawnParameters;

	private bool bUnSpawned = false;
	private AHazeActor HazeOwner;	
	private AActor CurrentSpawner = nullptr;
	private float CurrentSpawnTime;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		HazeOwner = Cast<AHazeActor>(Owner);
		CurrentSpawnTime = Time::GameTimeSeconds;
		check(HazeOwner != nullptr);
	}

	AActor GetSpawner() property
	{
		return CurrentSpawner;
	}

	float GetSpawnTime() property
	{
		return CurrentSpawnTime;
	}

	float GetSpawnedDuration() property
	{
		return Time::GetGameTimeSince(CurrentSpawnTime);
	}

	// Called by spawner after being spawned but before spawn patterns have done their stuff
    void OnSpawned(AActor _Spawner, FHazeActorSpawnParameters Params)
    {
		CurrentSpawner = _Spawner;
		bUnSpawned = false;
		SpawnParameters = Params;
		CurrentSpawnTime = Time::GameTimeSeconds;
		OnRespawn.Broadcast();
		AHazeActor Actor = Cast<AHazeActor>(Owner);
		UHazeCrumbSyncedActorPositionComponent NetworkMotionComp = (Actor != nullptr) ? UHazeCrumbSyncedActorPositionComponent::Get(Actor) : nullptr;
		if (NetworkMotionComp != nullptr)
			NetworkMotionComp.TransitionSync(this);	
	}

	// Called by spawner when all spawn patterns are done
	void OnPostSpawned()
	{
		OnPostRespawn.Broadcast();
	}

	// Called by owner or handling system when ready to be respawned
	UFUNCTION()
	void UnSpawn()
	{
		if (!ensure(HazeOwner != nullptr))
			return;

		// Only once until reset
		if (bUnSpawned)
			return;

		bUnSpawned = true;
		OnUnspawn.Broadcast(HazeOwner);
	}
}
