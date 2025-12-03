class UBootsEnforcerBehaviourCompoundCapability : UHazeCompoundCapability
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
					.Try(UBasicAIEntranceAnimationBehaviour())
					.Try(UHazeCompoundRunAll()
						.Add(UGravityWhipResistBehaviour())
						.Add(UGravityWhipStumbleBehaviour())
						.Add(UGravityBladeHitReactionBehaviour())
					)
					.Try(UHazeCompoundRunAll()
						.Add(UEnforcerTraversalEntranceBehaviour())
						.Add(UEnforcerTraverseToScenepointEntranceBehaviour())
						.Add(UEnforcerTraversalEvadeBehaviour())
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
								.Then(UEnforcerShotgunAttackBehaviour())
								.Then(UEnforcerWeaponRecoveryBehaviour())
							)
							.State(UHazeCompoundSequence()
								.Then(UEnforcerRocketLauncherAttackBehaviour())
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
					.Try(UHazeCompoundRunAll()
						.Add(UEnforcerFindBalancedTargetBehaviour())
						.Add(UBasicScenepointEntranceBehaviour())
						.Add(UBasicRoamBehaviour())
					);
	}
}

