class USanctuaryBabyWormBehaviourCompoundCapability : UHazeCompoundCapability
{
	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;
	default CapabilityTags.Add(BasicAITags::CompoundBehaviour);

	// Always active
	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		return true;
	}

	UFUNCTION(BlueprintOverride)
	UHazeCompoundNode GenerateCompound()
	{
		return UHazeCompoundSelector()
			.Try(USanctuaryBabyWormGrabbedBehaviour())
			.Try(UHazeCompoundRunAll()
				.Add(USanctuaryBabyWormFleeBehaviour())
				);
	}
}