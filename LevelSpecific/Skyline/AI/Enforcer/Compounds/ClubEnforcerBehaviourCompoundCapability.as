class UClubEnforcerBehaviourCompoundCapability : UHazeCompoundCapability
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
					.Try(UHazeCompoundRunAll()
						.Add(UGravityWhipThrowBehaviour())
						.Add(UGravityWhipGloryKillBehaviour())
						.Add(UGravityWhipLiftBehaviour())
						.Add(UGravityWhipStumbleBehaviour())
						.Add(UGravityBladeHitReactionBehaviour())
					)
					.Try(UBasicFallingBehaviour())
					.Try(UHazeCompoundRunAll()
						.Add(UBasicCrowdRepulsionBehaviour())
						.Add(UHazeCompoundSelector()
							// Combat
							.Try(UHazeCompoundRunAll()
								// .Add(USkylineEnforcerCombatScenepointEntranceBehaviour())
								.Add(UEnforcerPreventCombatMovementBehaviour())
								.Add(UHazeCompoundStatePicker()
									.State(UEnforcerGrenadeAttackBehaviour())
									.State(UHazeCompoundSequence()
										.Then(UEnforcerChargeMeleeApproachBehaviour())
										.Then(UEnforcerChargeMeleeAttackBehaviour())
									)
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
									.State(UHazeCompoundSequence()
										.Then(UEnforcerGloveAttackBehaviour())
										.Then(UEnforcerWeaponRecoveryBehaviour())
									)
									.State(UEnforcerFindProximityTargetBehaviour())
									.State(UEnforcerGentlemanFitnessQueueSwitcherBehaviour())
								)
								.Add(UEnforcerEvadeBehaviour())											
								.Add(UBasicFitnessCircleStrafeBehaviour())					
								.Add(UEnforcerChaseBehaviour())
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

