class UIslandBuzzerBehaviourCompoundCapability : UHazeCompoundCapability
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
				.Add(UIslandBuzzerWalkerRepulsionBehaviour())
				.Add(UHazeCompoundSelector()
					.Try(UHazeCompoundRunAll()
						.Add(UHazeCompoundStatePicker()
							.State(UIslandBuzzerLaserBehaviour())
							.State(UBasicGentlemanQueueSwitcherBehaviour())
						)
						.Add(UIslandBuzzerFlyingChaseBehaviour())
						.Add(UIslandBuzzerCombatMoveBehaviour())
						.Add(UBasicTrackTargetBehaviour())
					)
					.Try(UHazeCompoundRunAll()
						.Add(UBasicFindBalancedTargetBehaviour())
					)));
	}
}