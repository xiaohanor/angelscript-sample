// Activates set patterns when this pattern has been active for set duration. 
UCLASS(meta = (ShortTooltip="Activates set patterns when this pattern has been active for set duration."))
class UHazeActorSpawnPatternActivateOnDelay : UHazeActorSpawnPatternActivateOwnPatterns
{
	// How many seconds the spawn pattern needs to be active before activating set patterns.
	UPROPERTY(EditAnywhere, Category = "SpawnPattern")
	float Delay = 10.0;

	private float RemainingDelay = 0.0;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		Super::BeginPlay();
		RemainingDelay = Delay;
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
