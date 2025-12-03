struct FAIFirePattern
{
	// Interval before firing each bullet; first interval effectively increases telegraph duration so should usually be 0.0
	UPROPERTY(BlueprintReadOnly)
	TArray<float> ProjectileIntervals;

	int GetNumberOfProjectiles() const property
	{
		return ProjectileIntervals.Num();
	}
}

class UAIFirePatterns : UDataAsset
{
	UPROPERTY()
	TArray<FAIFirePattern> Patterns;
}

class UAIFirePatternManager : UActorComponent
{
	private TArray<FAIFirePattern>	AvailablePatterns;
	private TArray<FAIFirePattern>	UsedPatterns;

	bool IsInitialized() const
	{
		return (AvailablePatterns.Num() > 0);
	}

	void Initialize(UAIFirePatterns FirePatterns)
	{
		check(!IsInitialized(), "Never initialize fire pattern manager twice!");
		AvailablePatterns = FirePatterns.Patterns;
		AvailablePatterns.Shuffle();
	}

	FAIFirePattern ConsumePattern()
	{
		if (AvailablePatterns.Num() == 0)
			return FAIFirePattern();

		if ((AvailablePatterns.Num() == 1) && (UsedPatterns.Num() == 0))
			return AvailablePatterns[0]; // Only one pattern in total

		if (AvailablePatterns.Num() > 1)
		{
			// Use last pattern
			UsedPatterns.Add(AvailablePatterns.Last());	
			AvailablePatterns.RemoveAt(AvailablePatterns.Num() - 1);
			return UsedPatterns.Last();
		}

		// We've used all available patterns, re-use all but the last one
		FAIFirePattern Pattern = AvailablePatterns.Last();
		AvailablePatterns = UsedPatterns;
		AvailablePatterns.Shuffle();
		UsedPatterns.Empty(AvailablePatterns.Num() + 1);
		UsedPatterns.Add(Pattern);
		return UsedPatterns.Last();
	}
}

namespace AIFirePattern
{
	UAIFirePatternManager GetOrCreateManager(AActor User, UAIFirePatterns FirePatterns)
	{
		if (!IsValid(User) || (User.Level == nullptr))
			return nullptr;

		// User.LevelScriptActor will only accept HazeLevelScriptActors, which won't work in some test levels.
		AActor Owner = User.Level.LevelScriptActor;

		// Never place manager on persistent level
		if (!IsValid(Owner) || Owner.Level.IsPersistentLevel())
			Owner = Game::Mio; // Default to a player as owner instead.

		UAIFirePatternManager Manager = UAIFirePatternManager::GetOrCreate(Owner, FirePatterns.Name);
		if (!Manager.IsInitialized())
			Manager.Initialize(FirePatterns);
		return Manager;
	}
}
