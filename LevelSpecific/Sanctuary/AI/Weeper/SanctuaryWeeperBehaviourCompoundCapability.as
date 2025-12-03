class USanctuaryWeeperBehaviourCompoundCapability : UHazeCompoundCapability
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
			.Try(UBasicAIEntranceAnimationBehaviour())
			.Try(UHazeCompoundRunAll()
				.Add(UBasicCrowdRepulsionBehaviour())
				.Add(UHazeCompoundSelector()
					.Try(UHazeCompoundRunAll()						
						.Add(UHazeCompoundStatePicker()
							.State(USanctuaryWeeperFreezeBehaviour())
							.State(USanctuaryWeeperAttackBehaviour())
							.State(UBasicFindProximityTargetBehaviour())
						)
						// .Add(USanctuaryWeeperStrafeAdvanceBehaviour())
						.Add(USanctuaryWeeperChaseBehaviour())
					)
					.Try(UHazeCompoundRunAll()
						.Add(UBasicFindPriorityTargetBehaviour())
						.Add(UBasicFindBalancedTargetBehaviour())
					)));
	}
}