
namespace HazeActorSpawnPattern
{
	void ActivateAllStartDeactivatedPatterns(AActor SpawnerActor, FInstigator Instigator, EInstigatePriority Priority)
	{
		TArray<UHazeActorSpawnPattern> SpawnPatterns;
		SpawnerActor.GetComponentsByClass(SpawnPatterns);
		for (UHazeActorSpawnPattern Pattern : SpawnPatterns)
		{
			if (!Pattern.IsCompleted() && !Pattern.ShouldStartActive())
				Pattern.ActivatePattern(Instigator, Priority);
		}
	}

	void ActivateIncompletePatternsByTag(AActor SpawnerActor, FName Tag, FInstigator Instigator, EInstigatePriority Priority)
	{
		TArray<UHazeActorSpawnPattern> SpawnPatterns;
		SpawnerActor.GetComponentsByClass(SpawnPatterns);
		for (UHazeActorSpawnPattern Pattern : SpawnPatterns)
		{
			if (!Pattern.IsCompleted() && Pattern.HasTag(Tag))
				Pattern.ActivatePattern(Instigator, Priority);
		}
	}

	void GetNamedPatterns(AActor Owner, TArray<FName> NamesOfPatterns, TArray<UHazeActorSpawnPattern>& OutPatterns)
	{
		TArray<UHazeActorSpawnPattern> SpawnPatterns;
		Owner.GetComponentsByClass(SpawnPatterns);
		for (FName PatternName : NamesOfPatterns)
		{
			for (int i = SpawnPatterns.Num() - 1; i >= 0; i--)
			{
				if (PatternName.IsEqual(SpawnPatterns[i].Name))
				{
					// Found a pattern we should be activating
					OutPatterns.Add(SpawnPatterns[i]);
					SpawnPatterns.RemoveAtSwap(i);
					break; // Names are unique
				}
			}
		}
	}

	UHazeActorSpawnPattern GetPatternByName(AActor Owner, FName PatternName)
	{
		TArray<UHazeActorSpawnPattern> SpawnPatterns;
		Owner.GetComponentsByClass(SpawnPatterns);
		for (UHazeActorSpawnPattern Pattern : SpawnPatterns)
		{
			if (PatternName.IsEqual(Pattern.Name))
				return Pattern;
		}
		return nullptr;
	}

	void GetSpawnClasses(AActor Owner, TArray<TSubclassOf<AHazeActor>>& OutSpawnClasses)
	{
		TArray<UHazeActorSpawnPattern> SpawnPatterns;
		Owner.GetComponentsByClass(SpawnPatterns);
		for (UHazeActorSpawnPattern Pattern : SpawnPatterns)
		{	
			Pattern.GetSpawnClasses(OutSpawnClasses);
		}
	}	
}
