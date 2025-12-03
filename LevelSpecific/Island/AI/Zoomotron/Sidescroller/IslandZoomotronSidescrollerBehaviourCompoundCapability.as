class UIslandZoomotronSidescrollerBehaviourCompoundCapability : UHazeCompoundCapability
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
				.Add(UIslandZoomotronSidescrollerCrowdRepulsionBehaviour())
				.Add(UBasicScenepointEntranceBehaviour())
				.Add(UHazeCompoundSelector()
					.Try(UIslandZoomotronDamageReactionBehaviour())
					.Try(UHazeCompoundRunAll()
						.Add(UHazeCompoundStatePicker()
							.State(UIslandZoomotronSidescrollerAttackBehaviour())
							.State(UBasicFindProximityTargetBehaviour())
							.State(UBasicGentlemanQueueSwitcherBehaviour())
						)			
						.Add(UIslandZoomotronSidescrollerChaseBehaviour())
						.Add(UBasicTrackTargetBehaviour())
					)
					.Try(UHazeCompoundRunAll()
						.Add(UBasicFindBalancedTargetBehaviour())
					)
				);
	}
}
