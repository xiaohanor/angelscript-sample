// Activates another spawner when this pattern has been active for set duration
UCLASS(meta = (ShortTooltip="Activates another spawner when this pattern has been active for set duration."))
class UHazeActorSpawnPatternOtherActivateOnDelay : UHazeActorSpawnPatternActivateOtherSpawner
{
	// How many seconds the spawn pattern needs to be active before activating the other spawner.
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
		if (RemainingDelay <= 0.0)
			NetActivateOtherSpawner();
	}

	void ResetPattern() override
	{
		Super::ResetPattern();
		RemainingDelay = 0.0;
	}
}
