class UCoastPoltroonCompoundCapability : UHazeCompoundCapability
{
	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;

	// Always active
	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		return true;
	}

	UFUNCTION(BlueprintOverride)
	UHazeCompoundNode GenerateCompound()
	{
		return 	UHazeCompoundSelector()
					.Try(UHazeCompoundRunAll()
						.Add(UCoastPoltroonSetTargetBehaviour())
						.Add(UHazeCompoundSequence()
							.Then(UCoastPoltroonAttackBehaviour())
						)
					)
					.Try(UBasicFindTargetBehaviour());
	}
}

