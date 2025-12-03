class USanctuaryGhostBehaviourCompoundCapability : UHazeCompoundCapability
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
					// .Try(USanctuaryGhostPetrifyBehaviour())
					.Try(UHazeCompoundRunAll()
						.Add(UDarkPortalReactionBehaviour())
						.Add(UDarkPortalEscapeBehaviour())
						.Add(UHazeCompoundStatePicker()
							.State(UHazeCompoundSequence()
								.Then(USanctuaryGhostChargeBehaviour())
								.Then(USanctuaryGhostRecoverBehaviour())
							)
							.State(UBasicFindProximityTargetBehaviour())
							.State(UBasicGentlemanQueueSwitcherBehaviour())
						)
						.Add(UElementalStingerAvoidLightBehaviour())						
						.Add(USanctuaryGhostCircleBehaviour())						
						.Add(UBasicFlyingEvadeBehaviour())
						.Add(UBasicFlyingChaseBehaviour())
						.Add(UBasicTrackTargetBehaviour())
					)
					.Try(UHazeCompoundRunAll()
						.Add(UBasicFindBalancedTargetBehaviour())
					));
	}
}

