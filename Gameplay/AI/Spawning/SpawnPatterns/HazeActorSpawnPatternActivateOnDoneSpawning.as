// Activates another spawner when all currently active spawn patterns on our spawner is done spawning
UCLASS(meta = (ShortTooltip="Activates another spawner when all currently active spawn patterns on our spawner is done spawning"))
class UHazeActorSpawnPatternActivateOnDoneSpawning : UHazeActorSpawnPatternActivateOwnPatterns
{
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
				return; // Found a non-completed active pattern, skip to next update
		}

		// All patterns were completed!
		bWasCompleted = true;
		ActivatePatterns();
	}

	void ResetPattern() override
	{
		Super::ResetPattern();
		bWasCompleted = false;		
	}
}
