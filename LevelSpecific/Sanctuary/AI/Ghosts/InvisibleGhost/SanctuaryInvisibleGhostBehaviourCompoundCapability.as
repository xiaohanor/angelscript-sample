class USanctuaryInvisibleGhostBehaviourCompoundCapability : UHazeCompoundCapability
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
		return 	UHazeCompoundSelector()
					// .Try(USanctuaryGhostPetrifyBehaviour())
					.Try(UHazeCompoundRunAll()
						.Add(UDarkPortalReactionBehaviour())
						.Add(UDarkPortalEscapeBehaviour())
						.Add(UElementalStingerAvoidLightBehaviour())
						.Add(UHazeCompoundStatePicker()
							.State(UHazeCompoundSequence()
								.Then(USanctuaryInvisibleGhostChargeBehaviour())
								.Then(USanctuaryGhostRecoverBehaviour())
							)
							.State(UBasicGentlemanQueueSwitcherBehaviour())
						)
						.Add(UBasicCrowdRepulsionBehaviour())
						.Add(UBasicFindProximityTargetBehaviour())
						.Add(USanctuaryGhostCircleBehaviour())						
						.Add(UBasicFlyingEvadeBehaviour())
						.Add(UBasicFlyingChaseBehaviour())
						.Add(UBasicTrackTargetBehaviour())
					)
					.Try(UHazeCompoundRunAll()
						.Add(UBasicFindBalancedTargetBehaviour())
					);
	}
}

