// Spawn a single actor which is respawned when it dies after set respawn duration. 
UCLASS(meta = (ShortTooltip="Spawn a single actor which is respawned when it dies after set respawn duration."))
class UHazeActorSpawnPatternSingle : UHazeActorSpawnPattern
{
	default UpdateOrder = ESpawnPatternUpdateOrder::Early;
	default bCanEverSpawn = true;

	// Class to spawn
	UPROPERTY(EditAnywhere, BlueprintReadOnly, Category = SpawnPattern)
	TSubclassOf<AHazeActor> SpawnClass;

	// How long will we wait in between unspawn of an actor before next actor can be spawned
	UPROPERTY(EditAnywhere, BlueprintReadWrite, Category = SpawnPattern)
	float RespawnDuration = 1.0;

	// If true, this spawn pattern will repeat until deactivated. If false, we will only spawn MaxTotalSpawnedActors times.
	UPROPERTY(EditAnywhere, BlueprintReadWrite, Category = SpawnPattern)
	bool bInfiniteSpawn = false;

	// How many actors can be spawned in total before the pattern is depleted?
	UPROPERTY(EditAnywhere, BlueprintReadWrite, Category = SpawnPattern, meta = (EditCondition = !bInfiniteSpawn, EditConditionHides))
	int MaxTotalSpawnedActors = 1;

	private AHazeActor SpawnedActor;
	private float SpawnTime = 0.0;
	private int NumSpawn = 0;

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
		if (SpawnedActor != nullptr)
		 	return;
		if (Time::GameTimeSeconds < SpawnTime)
			return;

		SpawnBatch.Spawn(this, SpawnClass);
	}

	bool IsCompleted() const override
	{
		if (!bInfiniteSpawn && (NumSpawn >= MaxTotalSpawnedActors))
			return true;
		return false;
	}

	void OnSpawn(AHazeActor Actor) override
	{
		this.SpawnedActor = Actor;
		NumSpawn++;
	}

	void OnUnspawn(AHazeActor UnspawnedActor) override
	{
		if (UnspawnedActor != SpawnedActor)
			return;
		SpawnedActor = nullptr;
		SpawnTime = Time::GameTimeSeconds + RespawnDuration;
	}

	void ResetPattern() override
	{
		Super::ResetPattern();
		SpawnTime = 0.0;
		NumSpawn = 0;
	}
}
