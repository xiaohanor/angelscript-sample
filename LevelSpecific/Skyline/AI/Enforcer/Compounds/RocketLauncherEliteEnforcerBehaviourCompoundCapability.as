class URocketLauncherEliteEnforcerBehaviourCompoundCapability : UHazeCompoundCapability
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
					.Try(USkylineEnforcerJumpEntranceBehaviour())
					.Try(USkylineEnforcerSplineEntranceBehaviour())
					.Try(USkylineEnforcerExposedBehaviour())
					.Try(UEnforcerAreaAttackBehaviour())
					.Try(UEnforcerBreakObstacleBehaviour())
					.Try(UBasicFallingBehaviour())
					.Try(UHazeCompoundRunAll()
						.Add(UBasicCrowdRepulsionBehaviour())
						.Add(UHazeCompoundSelector()
							// Combat
							.Try(UHazeCompoundRunAll()
								.Add(USkylineEnforcerCombatScenepointEntranceBehaviour())
								.Add(UEnforcerPreventCombatMovementBehaviour())								
								.Add(UHazeCompoundStatePicker()
									.State(UHazeCompoundSequence()
										.Then(UEnforcerRocketLauncherAttackBehaviour())
										.Then(UEnforcerRocketLauncherRecoveryBehaviour())
									)
									.State(UEnforcerProximityTargetBehaviour())
									.State(UEnforcerGentlemanFitnessQueueSwitcherBehaviour())
								)
								.Add(UEnforcerEvadeBehaviour())
								.Add(UHazeCompoundSelector()
									.Try(UHazeCompoundRunAll()
										.Add(UBasicFitnessCircleStrafeBehaviour())
										.Add(UEnforcerChaseBehaviour())
									)
								)
								.Add(UBasicShuffleBehaviour())
								.Add(UBasicTrackTargetBehaviour())
								.Add(UBasicRaiseAlarmBehaviour())
							)
							// Idle
							.Try(UHazeCompoundRunAll()
								.Add(UEnforcerFindBalancedTargetBehaviour())				
							)
						)
					);
	}
}