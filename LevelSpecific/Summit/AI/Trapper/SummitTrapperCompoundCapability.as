class USummitTrapperCompoundCapability : UHazeCompoundCapability
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
				.Try(UHazeCompoundRunAll()
					.Add(USummitCrystalEscapeBehaviour())
				)
				// Knockdown
				.Try(UHazeCompoundRunAll()
					.Add(USummitKnockdownBehaviour())						
				)
				.Try(USummitGrappleTraversalEntranceBehaviour())
				// Combat
				.Try(UHazeCompoundRunAll()
					.Add(USummitGrappleTraversalChaseBehaviour())
					.Add(UHazeCompoundStatePicker()
						.State(UHazeCompoundSequence()
							.Then(USummitTrapperTelegraphTrapBehaviour())
							.Then(USummitTrapperSlingTrapBehaviour())
							.Then(USummitTrapperHoldTrapBehaviour())
							.Then(USummitTrapperReturnTrapBehaviour())
							.Then(USummitRecoveryBehaviour())
						)
						.State(UBasicFindProximityTargetBehaviour())
						.State(UBasicGentlemanQueueSwitcherBehaviour())
					)
					.Add(UBasicEvadeBehaviour())
					.Add(UBasicChaseBehaviour())
					.Add(UBasicFitnessCircleStrafeBehaviour())
					.Add(UBasicTrackTargetBehaviour())
					.Add(UBasicRaiseAlarmBehaviour())
				)
				//If no target
				.Try(UHazeCompoundRunAll()
					.Add(UBasicFindBalancedTargetBehaviour())
				)
			);
	}
}