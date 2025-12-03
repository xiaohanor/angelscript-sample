// Spawn a wave of actors. When all actors in wave is dead another wave will spawned after set respawn duration.
UCLASS(meta = (ShortTooltip="Spawn a wave of actors. When all actors in wave is dead another wave will spawned after set respawn duration."))
class UHazeActorSpawnPatternWave : UHazeActorSpawnPattern
{
	default UpdateOrder = ESpawnPatternUpdateOrder::Early;
	default bCanEverSpawn = true;

	// Class to spawn
	UPROPERTY(EditAnywhere, BlueprintReadOnly, Category = SpawnPattern)
	TSubclassOf<AHazeActor> SpawnClass;

	// How many actors are spawned in each wave. NOTE: If you spawn more than a few, they will be divides in batches with intervals to avoid excessive load. 
	UPROPERTY(EditAnywhere, BlueprintReadWrite, Category = SpawnPattern)
	int WaveSize = 3;

	// How long will we wait in between unspawn of all actors of a wave until new wave is spawned
	UPROPERTY(EditAnywhere, BlueprintReadWrite, Category = SpawnPattern)
	float RespawnDuration = 1.0;

	// If true, this spawn pattern will repeat until deactivated. If false, we will only spawn MaxTotalWaves times.
	UPROPERTY(EditAnywhere, BlueprintReadWrite, Category = SpawnPattern)
	bool bInfiniteSpawn = false;

	// How many waves can be spawned in total before the pattern is depleted?
	UPROPERTY(EditAnywhere, BlueprintReadWrite, Category = SpawnPattern, meta = (EditCondition = !bInfiniteSpawn, EditConditionHides))
	int MaxTotalWaves = 1;

	private int UnspawnedCountDown = 0;
	private float SpawnTime = 0.0;
	private int NumSpawnedWaves = 0;
	private int NumSpawnedInCurrentWave = 0;
	
	private float BatchContinueTime = 0.0; 
	private const int MaxPerBatch = 5;
	private const float BatchInterval = 0.5;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		Super::BeginPlay();
		if (!ensure(SpawnClass.IsValid(), "SpawnClass is invalid!"))
		{
			// Uninitialized, this will not have any effect
			DeactivatePattern(this, EInstigatePriority::Override);
			return;
		}
	}

	UFUNCTION(BlueprintOverride)
	void ConstructionScript()
	{
		// Abstract classes can't be spawned
		if (SpawnClass.IsValid() && SpawnClass.Get().IsAbstract())
			SpawnClass = nullptr;
	}

	void GetSpawnClasses(TArray<TSubclassOf<AHazeActor>>& OutSpawnClasses) const override
	{
		if (!SpawnClass.IsValid())
			return;
		OutSpawnClasses.AddUnique(SpawnClass);
	}

	void UpdateControlSide(float DeltaTime, FHazeActorSpawnBatch& SpawnBatch) override
	{
		Super::UpdateControlSide(DeltaTime, SpawnBatch);

		if (IsCompleted())
			return;
		
		float CurTime = Time::GameTimeSeconds;
		if (BatchContinueTime != 0.0)
		{
			// We're spawning a large wave that had to be broken up
			if (CurTime > BatchContinueTime)
			{
				// NumSpawnedInCurrentWave is guaranteed up to date after one tick on control side
				int RemainingSpawn = WaveSize - NumSpawnedInCurrentWave; 
				if (RemainingSpawn <= MaxPerBatch)
				{
					// Batch is done!
					SpawnBatch.Spawn(this, SpawnClass, RemainingSpawn);
					BatchContinueTime = 0.0;
				}	
				else 
				{
					// More batches to come
					SpawnBatch.Spawn(this, SpawnClass, MaxPerBatch);
					BatchContinueTime = CurTime + BatchInterval;
				}
			}
			return;
		}

		if (UnspawnedCountDown > 0)
		 	return;
		if (CurTime < SpawnTime)
			return;

		// Spawn a wave
		if (WaveSize <= MaxPerBatch)
		{
			SpawnBatch.Spawn(this, SpawnClass, WaveSize);
		}
		else 
		{
			// Large wave, break up into batches
			SpawnBatch.Spawn(this, SpawnClass, MaxPerBatch);
			BatchContinueTime = CurTime + BatchInterval;
		}
	}

	bool IsCompleted() const override
	{
		if (!bInfiniteSpawn && (NumSpawnedWaves >= MaxTotalWaves))
			return true;
		return false;
	}

	void OnSpawn(AHazeActor SpawnedActor) override
	{
		if (NumSpawnedInCurrentWave == 0)
			UnspawnedCountDown = WaveSize;
		NumSpawnedInCurrentWave++;
		if (NumSpawnedInCurrentWave == WaveSize)
		{
			NumSpawnedInCurrentWave = 0;
			NumSpawnedWaves++;
		}
	}

	void OnUnspawn(AHazeActor UnspawnedActor) override
	{
		UnspawnedCountDown--;
		if (UnspawnedCountDown == 0)
			SpawnTime = Time::GameTimeSeconds + RespawnDuration;
	}

	void ResetPattern() override
	{
		Super::ResetPattern();
		UnspawnedCountDown = 0;
		SpawnTime = 0.0;
		NumSpawnedWaves = 0;
		NumSpawnedInCurrentWave = 0;
		BatchContinueTime = 0.0; 
	}
}
