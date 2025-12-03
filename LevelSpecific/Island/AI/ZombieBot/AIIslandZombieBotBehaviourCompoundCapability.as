class UAIIslandZombieBotBehaviourCompoundCapability : UHazeCompoundCapability
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
			.Try(UHazeCompoundRunAll()
				.Add(UBasicCrowdRepulsionBehaviour())
				.Add(UBasicFindBalancedTargetBehaviour())
				.Add(UBasicGentlemanQueueSwitcherBehaviour())					
				.Add(UBasicTrackTargetBehaviour())
				.Add(UBasicChaseBehaviour())
			);
	}
}