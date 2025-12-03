class USanctuaryDodgerBehaviourCompoundCapability : UHazeCompoundCapability
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
					.Try(USanctuaryDodgerWakeBehaviour())
					.Try(UHazeCompoundRunAll()						
						.Add(UDarkPortalReactionBehaviour())
						.Add(UBasicStartFleeingBehaviour())
						.Add(UBasicFleeAlongSplineBehaviour())
						.Add(USanctuaryDodgerScenepointLandBehaviour())
						.Add(UHazeCompoundStatePicker()
							.State(USanctuaryDodgerRangedAttackBehaviour())
							.State(UHazeCompoundSequence()
								.Then(USanctuaryDodgerChargeBehaviour())
								.Then(USanctuaryDodgerChargeRecoveryBehaviour()))
							.State(UBasicGentlemanQueueSwitcherBehaviour())
							)				
						.Add(USanctuaryDodgerGrabDamageBehaviour())
						.Add(USanctuaryDodgerGrabReleaseBehaviour())
						.Add(UBasicFlyingChaseBehaviour())
						.Add(UBasicFlyingFitnessCircleStrafeBehaviour())
						.Add(UBasicFlyingEvadeBehaviour())
						.Add(UBasicTrackTargetBehaviour())
						.Add(UBasicRaiseAlarmBehaviour())
					)
					.Try(UHazeCompoundRunAll()
						.Add(UBasicFindBalancedTargetBehaviour())
						.Add(USanctuaryDodgerSleepBehaviour())
					)
				);
	}
}

