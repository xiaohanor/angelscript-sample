// Activates set patterns when a set number of enemies have died while this pattern was active
UCLASS(meta = (ShortTooltip="Activates set patterns when a set number of enemies have died while this pattern was active."))
class UHazeActorSpawnPatternActivateOnDeaths : UHazeActorSpawnPatternActivateOwnPatterns
{
	// Activate set patterns when this many spawned actors have
	UPROPERTY(EditAnywhere, Category = "SpawnPattern")
	int DeathCount = 1;

	private int NumberOfDeaths = 0;
	private bool bWasCompleted = false;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		Super::BeginPlay();
		UHazeActorSpawnerComponent OwnSpawner = UHazeActorSpawnerComponent::Get(Owner);
		OwnSpawner.OnPostUnspawn.AddUFunction(this, n"OnDeath");
	}

	UFUNCTION()
	private void OnDeath(AHazeActor UnspawnedActor, UHazeActorSpawnerComponent Spawner, UHazeActorSpawnPattern SpawningPattern)
	{
		if (!IsActivePattern())
			return;
		if (IsCompleted())
			return;
		if (Spawner.Owner != Owner)
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

		// Enough bloodshed, let new patterns take the burden
		bWasCompleted = true;
		ActivatePatterns();
	}

	void ResetPattern() override
	{
		Super::ResetPattern();
		NumberOfDeaths = 0;
		bWasCompleted = false;
	}
}
