// Activates another spawner when all currently active spawn patterns on our spawner has been completed.
UCLASS(meta = (ShortTooltip="Activates another spawner when all currently active spawn patterns on our spawner has been completed."))
class UHazeActorSpawnPatternOtherActivateOnCompleted : UHazeActorSpawnPatternActivateOtherSpawner
{
	// Activate others spawner when all spawn patterns of this tag is complete. If name is none, all spawn patterns need to be complete.
	UPROPERTY(EditAnywhere, Category = "SpawnPattern")
	FName TagCompleted = NAME_None;

	private TArray<UHazeActorSpawnPattern> RelevantSpawnPatterns;
	private bool bWasCompleted = false;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		Super::BeginPlay();

		TArray<UHazeActorSpawnPattern> SpawnPatterns;
		Owner.GetComponentsByClass(SpawnPatterns);		
		for (UHazeActorSpawnPattern Pattern : SpawnPatterns)
		{
			if (Pattern == this)
				continue;
			if (!Pattern.CanSpawn()) 
				continue;
			RelevantSpawnPatterns.Add(Pattern);
		}
		if (RelevantSpawnPatterns.Num() == 0)
		{
			DeactivatePattern(this, EInstigatePriority::Override);
			return;
		}
	}

	bool IsCompleted() const override
	{
		return bWasCompleted;
	}

	void UpdateControlSide(float DeltaTime, FHazeActorSpawnBatch& SpawnBatch) override
	{
		Super::UpdateControlSide(DeltaTime, SpawnBatch);

		for (UHazeActorSpawnPattern Pattern : RelevantSpawnPatterns)
		{
			if (Pattern.IsActivePattern() && !Pattern.IsCompleted())
				return; // Found a non-completed pattern, skip to next update
		}

		// All patterns were completed!
		bWasCompleted = true;
		NetActivateOtherSpawner();
	}

	void ResetPattern() override
	{
		Super::ResetPattern();
		bWasCompleted = false;
	}
}
