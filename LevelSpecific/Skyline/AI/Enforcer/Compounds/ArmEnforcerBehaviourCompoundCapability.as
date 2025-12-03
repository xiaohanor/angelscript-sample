class UArmEnforcerBehaviourCompoundCapability : UHazeCompoundCapability
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
			.Add(UBasicAIEntranceAnimationBehaviour())
			.Add(UEnforcerArmAttackBehaviour())
			.Add(UEnforcerArmReturnBehaviour())
			.Add(UHazeCompoundSelector()
				// Stunned
				.Try(UHazeCompoundRunAll()
					.Add(UEnforcerArmWhipStruggleBehaviour())
					//.Add(UBasicBehaviourKnockdown())
					.Add(UGravityWhipThrowBehaviour())
					.Add(UGravityWhipGloryKillBehaviour())
					.Add(UGravityWhipLiftBehaviour())
					.Add(UGravityWhipStumbleBehaviour())
					.Add(UGravityBladeHitReactionBehaviour())
				)
				// Combat
				.Try(UHazeCompoundRunAll()		
					.Add(UEnforcerTraversalEntranceBehaviour())
					.Add(UEnforcerTraverseToScenepointEntranceBehaviour())
					.Add(UEnforcerTraversalChaseBehaviour())
					.Add(UEnforcerPreventCombatMovementBehaviour())
					.Add(UHazeCompoundStatePicker()
						.State(UEnforcerJetpackRetreatBehaviour())
						.State(UEnforcerJetpackChaseBehaviour())
						.State(UEnforcerJetpackCircleStrafeBehaviour())							
						.State(UHazeCompoundSequence()
							.Then(UEnforcerRifleAttackBehaviour())
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
						.State(UEnforcerRollDodgeBehaviour())
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
					.Add(UBasicScenepointEntranceBehaviour())
					.Add(UBasicRoamBehaviour())
				)
			);
	}
}

