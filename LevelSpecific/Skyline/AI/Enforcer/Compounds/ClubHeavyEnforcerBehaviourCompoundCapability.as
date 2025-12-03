class UClubEnforcerHeavyBehaviourCompoundCapability : UHazeCompoundCapability
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
					// .Try(UEnforcerMeleeAttackBehaviour())
					.Try(UEnforcerAreaAttackBehaviour())
					.Try(UEnforcerBreakObstacleBehaviour())
					.Try(UHazeCompoundRunAll()
						.Add(UGravityWhipThrowBehaviour())
						.Add(UGravityWhipGloryKillBehaviour())
						.Add(UGravityWhipLiftBehaviour())
						.Add(UGravityWhipFlinchBehaviour())
						.Add(UGravityBladeHitReactionBehaviour())
					)
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
										.Then(UEnforcerRifleBulletStreamAttackBehaviour())
										.Then(UEnforcerWeaponRecoveryBehaviour())
									)
									.State(UHazeCompoundSequence()
										.Then(UEnforcerRocketLauncherAttackBehaviour())
										.Then(UEnforcerWeaponRecoveryBehaviour())
									)
									.State(UHazeCompoundSequence()
										.Then(UEnforcerShotgunAttackBehaviour())
										.Then(UEnforcerWeaponRecoveryBehaviour())
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