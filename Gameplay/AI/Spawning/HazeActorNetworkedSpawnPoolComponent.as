
namespace HazeActorNetworkedSpawnPoolStatics
{
	UHazeActorNetworkedSpawnPoolComponent GetOrCreateSpawnPool(TSubclassOf<AHazeActor> SpawnClass, AActor User)
	{
		if (!SpawnClass.IsValid() || (User == nullptr))
			return nullptr;

		// Pool should be owned by users level script actor so it'll be streamed out with it.
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

		// We create separate pools for users which are remotely and locally controlled
		bool bRemoteControlled = (User.HasControl() != PoolOwner.HasControl());
		FName PoolName = GetSpawnPoolName(SpawnClass, bRemoteControlled);
		UHazeActorNetworkedSpawnPoolComponent SpawnPool = Cast<UHazeActorNetworkedSpawnPoolComponent>(PoolOwner.GetComponent(UHazeActorNetworkedSpawnPoolComponent, PoolName));
		if (SpawnPool == nullptr)
		{
			SpawnPool = Cast<UHazeActorNetworkedSpawnPoolComponent>(PoolOwner.CreateComponent(UHazeActorNetworkedSpawnPoolComponent, PoolName));
			SpawnPool.SpawnClass = SpawnClass;
			SpawnPool.bRemoteControlled = bRemoteControlled;
		}
		return SpawnPool;
	}

	FName GetSpawnPoolName(TSubclassOf<AHazeActor> SpawnClass, bool bRemoteControlled)
	{
		if (!SpawnClass.IsValid())
			return bRemoteControlled ? n"DefaultSpawnPoolRemote" : n"DefaultSpawnPool";

		return FName("SpawnPool_" + (bRemoteControlled ? "Remote_" : "") + SpawnClass.Get().GetPathName());
	}
}

struct FHazeActorSpawnParameters
{
	UPROPERTY()
	FVector Location;

	UPROPERTY()
	FRotator Rotation;

	UPROPERTY()
	UScenepointComponent Scenepoint = nullptr;

	UPROPERTY()
	UHazeSplineComponent Spline = nullptr;

	UPROPERTY()
	UObject Spawner = nullptr;

	FHazeActorSpawnParameters()
	{
	}
	FHazeActorSpawnParameters(UObject _Spawner)
	{
		Spawner = _Spawner;
	}
}

struct FHazeActorRespawnableParameters
{
	UPROPERTY()
	AHazeActor RespawnedActor;

	UPROPERTY()
	FHazeActorSpawnParameters Params;
}

event void FOnHazeActorSpawned(AHazeActor SpawnedActor, FHazeActorSpawnParameters Params);

class UHazeActorNetworkedSpawnPoolComponent : UActorComponent
{
	UPROPERTY(Transient)
	TSubclassOf<AHazeActor> SpawnClass = nullptr;

	// Events broadcast when something is spawned by a specific spawner
	TMap<UObject, FOnHazeActorSpawned> OnSpawnedBySpawner;

	TArray<AHazeActor> Respawnables;
	TSet<AHazeActor> ControlRespawnables;  // Actors that are only respawnable on control side 
	TSet<AHazeActor> RemoteRespawnables;   // Actors that have been reported respawnable on remote side
	int SpawnCounter = 0;
	bool bRemoteControlled = false;

	bool IsMatchingControl(UObject Other)
	{
		if (bRemoteControlled)
			return Other.HasControl() != HasControl();
		return Other.HasControl() == HasControl();
	}

	UFUNCTION()
	AHazeActor SpawnControl(FHazeActorSpawnParameters Params)
	{
		TArray<AHazeActor> SpawnedActors;
		TArray<FHazeActorSpawnParameters> Batch;
		Batch.Add(Params);
		SpawnBatchControl(Batch, SpawnedActors);
		if (SpawnedActors.Num() == 0)
			return nullptr;
		return SpawnedActors[0];
	}

	void SpawnBatchControl(FHazeActorSpawnParameters Params, int NumberOfActorsToSpawn) 
	{
		TArray<AHazeActor> Dummy;
		TArray<FHazeActorSpawnParameters> Batch;
		for (int i = 0; i < NumberOfActorsToSpawn; i++)
		{
			Batch.Add(Params);			
		}
		SpawnBatchControl(Batch, Dummy);
	}

	// Convenience functions for when you do not immediately need to access the spawned actors
	void SpawnBatchControl(TArray<FHazeActorSpawnParameters> Batch)
	{
		TArray<AHazeActor> Dummy;
		SpawnBatchControl(Batch, Dummy);
	}

	void SpawnBatchControl(TArray<FHazeActorSpawnParameters> Batch, TArray<AHazeActor>& OutSpawnedActors)
	{
		OutSpawnedActors.Empty(Batch.Num());
		if (HasControl() == bRemoteControlled)
			return;

		// Clean respawnables list
		for (int i = Respawnables.Num() - 1; i >= 0; i--)
		{
			if (Respawnables[i] == nullptr)
				Respawnables.RemoveAtSwap(i);
		}

		// Respawn as many existing actors as possible
		int NumAvailableRespawnable = Respawnables.Num();
		int NumBatchRespawnable = Math::Min(NumAvailableRespawnable, Batch.Num());
		TArray<FHazeActorRespawnableParameters> RespawnBatch;
		RespawnBatch.SetNum(NumBatchRespawnable);
		for (int iRespawn = 0; iRespawn < NumBatchRespawnable; iRespawn++)
		{
			FHazeActorSpawnParameters Params = Batch[iRespawn];
			AHazeActor RespawnedActor = Respawnables[NumAvailableRespawnable - 1 - iRespawn];
			RespawnBatch[iRespawn].RespawnedActor = RespawnedActor;	
			RespawnBatch[iRespawn].Params = Params;
			OutSpawnedActors.Add(RespawnedActor);
			RespawnLocal(RespawnedActor, Params);
		}
		// Remove respawned actors
		Respawnables.SetNum(NumAvailableRespawnable - NumBatchRespawnable);

		// Spawn new actors
		TArray<FHazeActorSpawnParameters> NewSpawnBatch;
		NewSpawnBatch.Reserve(Batch.Num() - NumBatchRespawnable);
		for (int iSpawn = NumBatchRespawnable; iSpawn < Batch.Num(); iSpawn++)
		{
			NewSpawnBatch.Add(Batch[iSpawn]);
		}

		// Spawn actors remotely 
		NetRemoteSpawn(RespawnBatch, NewSpawnBatch);

		// Spawn actors on control side so we can use them immediately
		// We need to do that after calling the crumb function in case the spawned actor 
		// call any crumb functions on BaginPlay or we get a stall.
		for (int iSpawn = NumBatchRespawnable; iSpawn < Batch.Num(); iSpawn++)
		{
			AHazeActor NewSpawn = SpawnLocal(Batch[iSpawn]);
			OutSpawnedActors.Add(NewSpawn);
		}
	}

	// NB: This must be a netfunction not a crumbfunction, or any networked capabilities will cause major stalls
	UFUNCTION(NetFunction, NotBlueprintCallable)
	private void NetRemoteSpawn(TArray<FHazeActorRespawnableParameters> RespawnBatch, TArray<FHazeActorSpawnParameters> SpawnBatch)
	{
		// Non-controlled side only, since we call local spawn/respawn on control side directly to get spawned actor
		if (HasControl() != bRemoteControlled)
			return;
		
		for (FHazeActorRespawnableParameters Respawn : RespawnBatch)
		{
			RespawnLocal(Respawn.RespawnedActor, Respawn.Params);
		}

		for (FHazeActorSpawnParameters Params : SpawnBatch)
		{
			SpawnLocal(Params);
		}
	}

	private AHazeActor SpawnLocal(FHazeActorSpawnParameters Params)
	{
		ULevel Level = Owner.Level;
		// If the owner is in the persistent level, send in nullptr to get the DynamicSpawnLevel instead
		if(Level.IsPersistentLevel())
			Level = nullptr;

		// Spawn a new actor
		AActor Actor = SpawnActor(SpawnClass, Params.Location, Params.Rotation, NAME_None, true, Level);
        AHazeActor SpawnedActor = Cast<AHazeActor>(Actor);
		if (!ensure(SpawnedActor != nullptr, "Spawn pool failed to spawn actor of class " + SpawnClass.Get().Name + ". Check if class is abstract or notplacable."))
			return nullptr;
		SpawnedActor.MakeNetworked(this, FNetworkIdentifierPart(SpawnCounter));
		SpawnedActor.SetActorControlSide(this);
		FinishSpawningActor(SpawnedActor);
		SpawnCounter++;
		OnSpawnedBySpawner.FindOrAdd(Params.Spawner).Broadcast(SpawnedActor, Params);
		return SpawnedActor;
	}

	private void RespawnLocal(AHazeActor RespawnedActor, FHazeActorSpawnParameters Params)
	{
		RespawnedActor.TeleportActor(Params.Location, Params.Rotation, this);
		OnSpawnedBySpawner.FindOrAdd(Params.Spawner).Broadcast(RespawnedActor, Params);	
	}

	// Users must call this to let pool know that they can be respawned
	UFUNCTION()
	void UnSpawn(AHazeActor Respawnable)
	{
		if (!ensure(Respawnable.IsA(SpawnClass)))
			return;

		if (Network::IsGameNetworked())
		{
			if (HasControl() != bRemoteControlled)
			{
				// Controlled side
				if (RemoteRespawnables.Contains(Respawnable))
				{
					// Actor has been reported respawnable on remote side, make it available straight away
					RemoteRespawnables.Remove(Respawnable);
					if (ensure(!Respawnables.Contains(Respawnable)))
						Respawnables.Add(Respawnable);
				}
				else
				{
					// Actor is respawnable on control side, but not yet on remote.
					ControlRespawnables.Add(Respawnable);	
				}
			}
			else
			{ 
				// Non-controlled side, just report that it's respawnable on this side as well
				NetReportRespawnable(Respawnable);
			}
		}
		else
		{	
			// Non-network play, we can reuse actor immediately
			if (!Respawnables.Contains(Respawnable))
				Respawnables.Add(Respawnable);
		}
	}

	UFUNCTION(NetFunction, NotBlueprintCallable)
	void NetReportRespawnable(AHazeActor Respawnable)
	{
		// We only care about this on controlled side
		if (HasControl() != bRemoteControlled)
		{
			if (ControlRespawnables.Contains(Respawnable))
			{
				// Was respawnable on control side, it can now be respanwed
				ControlRespawnables.Remove(Respawnable);				
				if (ensure(!Respawnables.Contains(Respawnable)))
					Respawnables.Add(Respawnable);
			}
			else
			{
				// Not respawnable on control side yet, remember that remote side is ok with respawn.
				RemoteRespawnables.Add(Respawnable);
			}
		}
	}
}

