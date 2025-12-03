namespace HazeActorLocalSpawnPoolStatics
{
	UHazeActorLocalSpawnPoolComponent GetOrCreateSpawnPool(TSubclassOf<AHazeActor> SpawnClass, AActor User)
	{
		if (!SpawnClass.IsValid() || (User == nullptr))
			return nullptr;

		// User.LevelScriptActor will only accept HazeLevelScriptActors, which won't work in some test levels.
		AActor PoolOwner = User.Level.LevelScriptActor;

		// Only players are allowed to create spawn pools in the dynamic spawn level
		if (User.Level.IsDynamicSpawnLevel())
		{
			if (devEnsure(User.IsA(AHazePlayerCharacter) || Progress::IsLevelTestMap(User.Level.GetFullName()), "Only players are allowed to create spawn pool in the dynamic spawn level, use player which is responsible for " + User.GetName() + " or make sure it is spawned in a proper level."))			
				PoolOwner = (User.HasControl() == Game::Mio.HasControl()) ? Game::Mio : Game::Zoe;
			else
				return nullptr;
		}

		// Never place spawn pool in persistent level 
		if ((PoolOwner == nullptr) || User.Level.IsPersistentLevel())
			PoolOwner = (User.HasControl() == Game::Mio.HasControl()) ? Game::Mio : Game::Zoe;

		if (!ensure(PoolOwner != nullptr))
			return nullptr;

		FName PoolName = GetSpawnPoolName(SpawnClass);
		UHazeActorLocalSpawnPoolComponent SpawnPool = Cast<UHazeActorLocalSpawnPoolComponent>(PoolOwner.GetComponent(UHazeActorLocalSpawnPoolComponent, PoolName));
		if (SpawnPool == nullptr)
		{
			SpawnPool = Cast<UHazeActorLocalSpawnPoolComponent>(PoolOwner.CreateComponent(UHazeActorLocalSpawnPoolComponent, PoolName));
			SpawnPool.SpawnClass = SpawnClass;
		}
		return SpawnPool;
	}

	FName GetSpawnPoolName(TSubclassOf<AHazeActor> SpawnClass)
	{
		if (!SpawnClass.IsValid())
			return n"DefaultLocalSpawnPool";

		return FName("LocalSpawnPool_" + SpawnClass.Get().GetPathName());
	}
}

UCLASS(NotBlueprintable, NotPlaceable)
class UHazeActorLocalSpawnPoolComponent : UActorComponent
{
	UPROPERTY(Transient)
	TSubclassOf<AHazeActor> SpawnClass = nullptr;

	// Events broadcast when something is spawned by a specific spawner
	TMap<UObject, FOnHazeActorSpawned> OnSpawnedBySpawner;

	TArray<AHazeActor> Respawnables;

	UFUNCTION()
	AHazeActor Spawn(FHazeActorSpawnParameters Params)
	{
		for (int i = Respawnables.Num() - 1; i >= 0; i--)
		{
			if (Respawnables[i] == nullptr)
				Respawnables.RemoveAtSwap(i);
		}

		if (Respawnables.Num() > 0)
		{	
			// Respawn existing actor
			int LastIndex = Respawnables.Num() - 1;
			AHazeActor SpawnedActor = Respawnables[LastIndex];
			Respawnables.RemoveAt(LastIndex);
			SpawnedActor.TeleportActor(Params.Location, Params.Rotation, this);

			BroadcastOnSpawned(SpawnedActor, Params);

			return SpawnedActor;
		}

		ULevel Level = Owner.Level;
		// If the owner is in the persistent level, send in nullptr to get the DynamicSpawnLevel instead
		if(Level.IsPersistentLevel())
			Level = nullptr;

		// Spawn a new actor
		AActor Actor = SpawnActor(SpawnClass, Params.Location, Params.Rotation, NAME_None, true, Level);
        AHazeActor SpawnedActor = Cast<AHazeActor>(Actor);
		if (!ensure(SpawnedActor != nullptr))
			return nullptr;
		FinishSpawningActor(SpawnedActor);

		BroadcastOnSpawned(SpawnedActor, Params);
		
		return SpawnedActor;
	}

	private void BroadcastOnSpawned(AHazeActor SpawnedActor, FHazeActorSpawnParameters Params)
	{
		OnSpawnedBySpawner.FindOrAdd(Params.Spawner).Broadcast(SpawnedActor, Params);

		auto SpawnPoolEntryComp = UHazeActorLocalSpawnPoolEntryComponent::Get(SpawnedActor);
		if(SpawnPoolEntryComp != nullptr)
			SpawnPoolEntryComp.InternalOnSpawned(this);
	}

	// Users must call this to let pool know that they can be respawned
	UFUNCTION()
	void UnSpawn(AHazeActor Respawnable)
	{
		if (!ensure(Respawnable.IsA(SpawnClass)))
			return;

		auto SpawnPoolEntryComp = UHazeActorLocalSpawnPoolEntryComponent::Get(Respawnable);
		if(SpawnPoolEntryComp != nullptr)
			SpawnPoolEntryComp.InternalOnUnspawned();

		if (!Respawnables.Contains(Respawnable))
			Respawnables.Add(Respawnable);
		else
			check(false, "You tried to unspawn something that has already unspawned");
	}
}

