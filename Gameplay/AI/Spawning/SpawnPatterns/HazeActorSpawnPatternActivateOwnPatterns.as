// Base class for patterns that activates other patterns on this spawner
UCLASS(Abstract)
class UHazeActorSpawnPatternActivateOwnPatterns : UHazeActorSpawnPattern
{
	default UpdateOrder = ESpawnPatternUpdateOrder::Early;

	// Names of the patterns that will be activated
	UPROPERTY(NotVisible, BlueprintReadOnly, Category = "SpawnPattern")
	TArray<UHazeActorSpawnPattern> PatternsToActivate; 

	UPROPERTY(EditAnywhere, AdvancedDisplay, Category = "SpawnPattern")
	EInstigatePriority ActivationPriority = EInstigatePriority::Normal;

	// This should maintain update even though it won't spawn anything, as it can complete after spawning patterns are completed.
	bool NeedsUpdate() const override
	{
		return !IsCompleted(); 
	}

	void ActivatePatterns()
	{
		// Activate patterns! Note that this does not have to be replicated since pattern updating is on control side only.
		for (UHazeActorSpawnPattern Pattern : PatternsToActivate)
		{
			if (Pattern != nullptr)
				Pattern.ActivatePattern(this, ActivationPriority);
		}
	}
}
