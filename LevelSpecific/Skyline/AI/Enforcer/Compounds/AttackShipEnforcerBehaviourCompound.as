class UAttackShipEnforcerBehaviourCompound : UHazeCompoundCapability
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
					// Stunned
					.Try(UHazeCompoundRunAll()
						.Add(UGravityWhipThrowBehaviour())
						.Add(UGravityWhipGloryKillBehaviour())
						.Add(UGravityWhipLiftBehaviour())
						.Add(UGravityWhipStumbleBehaviour())
						.Add(UGravityBladeHitReactionBehaviour())
						.Add(UBasicAIEntranceAnimationBehaviour())
					)
					.Try(UHazeCompoundRunAll()
						.Add(UBasicCrowdRepulsionBehaviour())
						.Add(UHazeCompoundSelector()
							// Fleeing
							.Try(UEnforcerFleeBehaviour())
							// Combat
							.Try(UHazeCompoundRunAll()
								.Add(UEnforcerTraversalEntranceBehaviour())
								.Add(UEnforcerTraverseToScenepointEntranceBehaviour())
								.Add(UEnforcerPreventCombatMovementBehaviour())
								.Add(UHazeCompoundStatePicker()
									.State(UEnforcerAvoidGrenadesBehaviour())
									.State(UEnforcerGrenadeAttackBehaviour())
									.State(UHazeCompoundSequence()
										.Then(UEnforcerChargeMeleeApproachBehaviour())
										.Then(UEnforcerChargeMeleeAttackBehaviour())
									)
									.State(UHazeCompoundSequence()
										.Then(UEnforcerRifleBulletStreamAttackBehaviour())
										.Then(UEnforcerWeaponRecoveryBehaviour())
									)
									.State(UEnforcerFindProximityTargetBehaviour())
									.State(UEnforcerGentlemanFitnessQueueSwitcherBehaviour())
								)
								.Add(UEnforcerEvadeBehaviour())											
								.Add(UEnforcerChaseBehaviour())
								.Add(UBasicShuffleBehaviour())
								.Add(UBasicTrackTargetBehaviour())
								.Add(UBasicRaiseAlarmBehaviour())
							)
							// Idle
							.Try(UHazeCompoundRunAll()
								.Add(UEnforcerFindBalancedTargetBehaviour())
								.Add(UBasicScenepointEntranceBehaviour())
							)
						)	
					);
	}
}

