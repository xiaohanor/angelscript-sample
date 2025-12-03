// Activates set patterns when this pattern has been active for a random duration in given range.
UCLASS(meta = (ShortTooltip="Activates set patterns when this pattern has been active for a random duration in given range."))
class UHazeActorSpawnPatternActivateOnRandomDelay : UHazeActorSpawnPatternActivateOwnPatterns
{
	// How many seconds the spawn pattern needs to be active before activating set patterns.
	UPROPERTY(EditAnywhere, Category = "SpawnPattern")
	float MinDelay = 0.0;

	// How many seconds the spawn pattern needs to be active before activating set patterns.
	UPROPERTY(EditAnywhere, Category = "SpawnPattern")
	float MaxDelay = 1.0;

	private float RemainingDelay = 0.0;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		Super::BeginPlay();
		RemainingDelay = Math::RandRange(MinDelay, MaxDelay);
	}

	bool IsCompleted() const override
	{
		if (RemainingDelay > 0.0)
			return false;
		return true;
	}

	void UpdateControlSide(float DeltaTime, FHazeActorSpawnBatch& SpawnBatch) override
	{
		Super::UpdateControlSide(DeltaTime, SpawnBatch);
		RemainingDelay -= DeltaTime;
		if (RemainingDelay > 0.0)
			return;

		ActivatePatterns();
	}

	void ResetPattern() override
	{
		Super::ResetPattern();
		RemainingDelay = 0.0;
	}
}
