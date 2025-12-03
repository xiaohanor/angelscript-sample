class UIslandRollotronBehaviourCompoundCapability : UHazeCompoundCapability
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
					.Try(UIslandRollotronScenepointEntranceBehaviour())
					.Try(UHazeCompoundRunAll()
						.Add(UIslandRollotronDamageReactionBehaviour())
						.Add(UIslandRollotronDetonateBehaviour())
						.Add(UIslandRollotronChaseBehaviour())							
						.Add(UHazeCompoundStatePicker()
							.State(UBasicFindProximityTargetBehaviour())
							.State(UBasicGentlemanQueueSwitcherBehaviour())
						)				
					)
					.Try(UHazeCompoundRunAll()
						.Add(UBasicFindBalancedTargetBehaviour())
					)
				);
	}
}
