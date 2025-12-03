class USanctuaryRangedGhostBehaviourCompoundCapability : UHazeCompoundCapability
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
				// .Try(USanctuaryRangedGhostPetrifyBehaviour())
				.Try(UHazeCompoundRunAll()
					.Add(UDarkPortalReactionBehaviour())
					.Add(UDarkPortalEscapeBehaviour())
					.Add(UElementalStingerAvoidLightBehaviour())
					.Add(UHazeCompoundStatePicker()
						.State(USanctuaryRangedGhostRangedAttackBehaviour())
						.State(UBasicFindProximityTargetBehaviour())
						.State(UBasicGentlemanQueueSwitcherBehaviour())
					)
					.Add(USanctuaryRangedGhostCircleBehaviour())
					.Add(UBasicFlyingEvadeBehaviour())
					.Add(UBasicFlyingChaseBehaviour())
					.Add(UBasicTrackTargetBehaviour())
				)
				.Try(UHazeCompoundRunAll()
					.Add(UBasicFindBalancedTargetBehaviour())
				));
	}
}

