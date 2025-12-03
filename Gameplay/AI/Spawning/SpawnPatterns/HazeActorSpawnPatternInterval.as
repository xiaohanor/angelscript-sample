// Spawns actors at intervals until set number is active, then continues spawning after interval whenever a spawned actor dies.
UCLASS(meta = (ShortTooltip="Spawns actors at intervals until set number is active, then continues spawning after interval whenever a spawned actor dies."))
class UHazeActorSpawnPatternInterval : UHazeActorSpawnPattern
{
	default UpdateOrder = ESpawnPatternUpdateOrder::Early;
	default bCanEverSpawn = true;

	// Class to spawn
	UPROPERTY(EditAnywhere, BlueprintReadOnly, Category = SpawnPattern)
	TSubclassOf<AHazeActor> SpawnClass;

	// How many actors can be spawned in total before the pattern is depleted?
	UPROPERTY(EditAnywhere, BlueprintReadWrite, Category = SpawnPattern, meta = (EditCondition = !bInfiniteSpawn, EditConditionHides))
	int MaxTotalSpawnedActors = 1;

	// How many actors can be alive at a time?
	UPROPERTY(EditAnywhere, BlueprintReadWrite, Category = SpawnPattern)
	int MaxActiveSpawnedActors = 1;

	// How long will we wait after each spawn/unspawn until we spawn the next actor from this sequence?
	UPROPERTY(EditAnywhere, BlueprintReadWrite, Category = SpawnPattern)
	float Interval = 1.0;

	// If greater than zero, we use RespawnDelay instead of Interval for first respawn after having reached MaxActiveSpawnedActors
	UPROPERTY(EditAnywhere, BlueprintReadWrite, Category = SpawnPattern)
	float RespawnDelay = 0;

	// If true, this spawn pattern will repeat until deactivated. If false, we will only spawn MaxTotalSpawnedActors times.
	UPROPERTY(EditAnywhere, BlueprintReadWrite, Category = SpawnPattern)
	bool bInfiniteSpawn = false;

	private float SpawnTime = 0.0;
	private int NumActiveSpawn = 0;
	private int NumTotalSpawn = 0;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		Super::BeginPlay();
		if (!devEnsure(SpawnClass.IsValid(), f"SpawnClass is invalid on {Owner} ({this})!"))
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

		if (!bInfiniteSpawn && (MaxActiveSpawnedActors > MaxTotalSpawnedActors))
			MaxActiveSpawnedActors = MaxTotalSpawnedActors;
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
		if (Time::GameTimeSeconds < SpawnTime)
			return;

		// Spawn actor
		SpawnBatch.Spawn(this, SpawnClass);
	}

	bool IsCompleted() const override
	{
		if (!bInfiniteSpawn && (NumTotalSpawn >= MaxTotalSpawnedActors))
			return true;
		return false;
	}

	void OnSpawn(AHazeActor SpawnedActor) override
	{
		NumActiveSpawn++;
		NumTotalSpawn++;
		if (NumActiveSpawn < MaxActiveSpawnedActors)
			SpawnTime = Time::GameTimeSeconds + Interval;
		else 	
			SpawnTime = BIG_NUMBER;
	}

	void OnUnspawn(AHazeActor UnspawnedActor) override
	{
		NumActiveSpawn--;
		if (SpawnTime == BIG_NUMBER)
			SpawnTime = Time::GameTimeSeconds + (RespawnDelay > 0 ? RespawnDelay : Interval);
	}

	void ResetPattern() override
	{
		Super::ResetPattern();
		SpawnTime = 0.0;
		NumActiveSpawn = 0;
		NumTotalSpawn = 0;
	}
}
