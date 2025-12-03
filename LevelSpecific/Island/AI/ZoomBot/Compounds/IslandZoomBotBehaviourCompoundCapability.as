class UIslandZoomBotBehaviourCompoundCapability : UHazeCompoundCapability
{
	// Crumb synced even though we might have large numbers of AIs, 
	// but note that almost all behaviours are ActivatesOnControlOnly
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
					.Try(UIslandZoomBotShieldBusterStunnedBehaviour())
					.Try(UHazeCompoundRunAll()
						.Add(UHazeCompoundStatePicker()
							.State(UIslandZoomBotChargeBehaviour())
							.State(UBasicGentlemanQueueSwitcherBehaviour())
							.State(UBasicFindProximityTargetBehaviour())
						)		
						.Add(UBasicFlyingChaseBehaviour())
						.Add(UBasicFlyingCircleStrafeBehaviour())
						.Add(UBasicTrackTargetBehaviour())
					)
					.Try(UHazeCompoundRunAll()
						.Add(UBasicFindBalancedTargetBehaviour())
					)
				);
	}
}
