class USummitKnightBroCompoundCapability : UHazeCompoundCapability
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
		return 	UHazeCompoundRunAll()
				.Add(UBasicCrowdRepulsionBehaviour())
				.Add(UHazeCompoundSelector()
					.Try(UHazeCompoundRunAll()
						.Add(USummitKnightDamageBehaviour())
					)
					.Try(UHazeCompoundRunAll()
						.Add(USummitKnightCrystalEscapeBehaviour())
					)
					// Knockdown
					.Try(UHazeCompoundRunAll()
						.Add(USummitKnightKnockdownBehaviour())						
					)
					.Try(USummitLeapTraversalEntranceBehaviour()) 
					// Combat
					.Try(UHazeCompoundRunAll()
						.Add(USummitKnightAcidShieldBehaviour())
						.Add(USummitKnightAcidDodgeBehaviour())
						)
					.Try(USummitKnightShieldBlockBehaviour())
					.Try(UHazeCompoundRunAll()			
						.Add(USummitKnightProximityFocusBehaviour())
						.Add(USummitKnightReformShieldBehaviour())
						.Add(USummitKnightReformSpearBehaviour())
						.Add(UHazeCompoundStatePicker()							
							.State(USummitKnightChargeBehaviour())
							.State(UBasicGentlemanQueueSwitcherBehaviour())
							)
						.Add(USummitLeapTraversalChaseBehaviour())
						.Add(UBasicChaseBehaviour())
						.Add(UBasicEvadeBehaviour())
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