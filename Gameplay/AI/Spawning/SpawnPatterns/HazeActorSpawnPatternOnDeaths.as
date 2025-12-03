event void FHazeActorSpawnPatternOnDeathsOnCompletedSignature();

// Completes when set number of actors spawned by this spawner has died.
UCLASS(meta = (ShortTooltip="Completes when set number of actors spawned by this spawner has died."))
class UHazeActorSpawnPatternOnDeaths : UHazeActorSpawnPattern
{
	default UpdateOrder = ESpawnPatternUpdateOrder::Early;

	// Complete when this many spawned actors has died.
	UPROPERTY(EditAnywhere, Category = "SpawnPattern")
	int DeathCount = 1;

	private int NumberOfDeaths = 0;
	private bool bWasCompleted = false;

	UPROPERTY()
	FHazeActorSpawnPatternOnDeathsOnCompletedSignature OnCompleted;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		Super::BeginPlay();

		UHazeActorSpawnerComponent OwnSpawner = UHazeActorSpawnerComponent::Get(Owner);
		OwnSpawner.OnPostSpawn.AddUFunction(this, n"OnPostSpawn");
	}

	UFUNCTION()
	private void OnPostSpawn(AHazeActor SpawnedActor, UHazeActorSpawnerComponent Spawner,
	                         UHazeActorSpawnPattern SpawningPattern)
	{
		if (Spawner.Owner != Owner)
			return;
		UBasicAIHealthComponent HealthComp = UBasicAIHealthComponent::Get(SpawnedActor);
		HealthComp.OnDie.AddUFunction(this, n"OnDeath");
	}

	UFUNCTION()
	private void OnDeath(AHazeActor ActorBeingKilled)
	{
		if (!IsActivePattern())
			return;
		if (IsCompleted())
			return;
		NumberOfDeaths++;
	}

	bool IsCompleted() const override
	{
		return bWasCompleted;
	}

	void UpdateControlSide(float DeltaTime, FHazeActorSpawnBatch& SpawnBatch) override
	{
		Super::UpdateControlSide(DeltaTime, SpawnBatch);

		if (NumberOfDeaths < DeathCount)
			return;

		bWasCompleted = true;
		OnCompleted.Broadcast();
	}

	void ResetPattern() override
	{
		Super::ResetPattern();
		NumberOfDeaths = 0;
		bWasCompleted = false;
	}
}
