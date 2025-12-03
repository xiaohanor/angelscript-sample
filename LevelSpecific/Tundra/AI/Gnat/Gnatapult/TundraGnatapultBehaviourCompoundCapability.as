class UTundraGnatapultBehaviourCompoundCapability : UHazeCompoundCapability
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
		return UHazeCompoundRunAll()
				.Add(UBasicCrowdRepulsionBehaviour())
				.Add(UHazeCompoundSelector()
					.Try(UTundraGnatBeaverSpearEntryBehaviour())
					.Try(UTundraGnatClimbEntryBehaviour())
					.Try(UTundraGnatapultPositioningBehaviour())
					.Try(UTundraGnatapultAttackBehaviour())
					.Try(UTundraGnatapultReloadBehaviour())
				);
	}
}
