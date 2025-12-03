class UIslandDyadBehaviourCompoundCapability : UHazeCompoundCapability
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
				.Add(UIslandDyadDeployBehaviour())
				.Add(UBasicCrowdRepulsionBehaviour())
				.Add(UIslandDyadFindOtherBehaviour())
				.Add(UIslandDyadLaserBehaviour())
				.Add(UHazeCompoundSelector()
					.Try(UHazeCompoundRunAll()
						.Add(UIslandDyadChaseBehaviour())
						.Add(UBasicTrackTargetBehaviour())
					)
					.Try(UHazeCompoundRunAll()
						.Add(UBasicFindPriorityTargetBehaviour())
					)));
	}
}