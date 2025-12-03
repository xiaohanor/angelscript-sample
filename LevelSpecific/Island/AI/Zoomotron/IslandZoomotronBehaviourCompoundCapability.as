class UIslandZoomotronBehaviourCompoundCapability : UHazeCompoundCapability
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
					.Try(UIslandZoomotronDamageReactionBehaviour())
					.Try(UBasicScenepointEntranceBehaviour())
					//.Try(UBasicSplineEntranceBehaviour())
					.Try(UHazeCompoundRunAll()
						.Add(UHazeCompoundSelector()
							.Try(UIslandZoomotronChargeBehaviour())
							.Try(UIslandZoomotronChaseBehaviour())
							.Try(UIslandZoomotronFlyingCircleStrafeBehaviour())
						)
						.Add(UHazeCompoundStatePicker()
							.State(UIslandZoomotronAttackBehaviour())
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
