class UHoveringDualWieldingEnforcerBehaviourCompoundCapability : UHazeCompoundCapability
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
					.Add(UBasicSplineEntranceBehaviour())
					.Add(UHazeCompoundSelector()
						.Try(UHazeCompoundRunAll()
							.Add(UEnforcerHoveringGravityWhipThrownBehaviour())
							.Add(UGravityWhipGloryKillBehaviour())
							.Add(UGravityWhipLiftBehaviour())
							.Add(UHazeCompoundSequence()
								.Then(UEnforcerHoveringGravityWhipBillboardImpactBehaviour())
								.Then(UEnforcerHoveringGravityWhipBillboardImpactRecoverBehaviour()))
							.Add(UEnforcerGravityWhipThrowRecoverBehaviour())
							.Add(UGravityBladeHitReactionBehaviour())
							.Add(UBasicAIEntranceAnimationBehaviour())
						)
						.Try(UHazeCompoundRunAll()
							.Add(UEnforcerTraversalEntranceBehaviour())
							.Add(UEnforcerTraverseToScenepointEntranceBehaviour())
							.Add(UEnforcerPreventCombatMovementBehaviour())
							.Add(UHazeCompoundStatePicker()
								.State(UHazeCompoundSequence()
									.Then(USkylineEnforcerStickyBombLauncherDualWieldingAttackBehaviour())
									.Then(UEnforcerWeaponRecoveryBehaviour())
								)
								.State(UHazeCompoundSequence()
									.Then(UEnforcerRifleDualWieldingAttackBehaviour())
									.Then(UEnforcerWeaponRecoveryBehaviour())
								)								
								.State(UBasicGentlemanQueueSwitcherBehaviour())							
							)
							.Add(UHazeCompoundSelector()
								.Try(UEnforcerPrioritySwitchTargetBehaviour())
								.Try(UEnforcerFindProximityTargetBehaviour())
							)
							.Add(UEnforcerHoverScenepointRepositionBehaviour())											
							.Add(UEnforcerHoverChaseBehaviour())
							.Add(UEnforcerHoverAtScenepoint())											
							.Add(UEnforcerHoverAvoidWallsBehaviour())
							.Add(UEnforcerHoverDriftBehaviour())
							.Add(UBasicTrackTargetBehaviour())
							.Add(UBasicRaiseAlarmBehaviour())
						)
						// Idle
						.Try(UHazeCompoundRunAll()
							.Add(UEnforcerFindBalancedTargetBehaviour())
						)
					);
	}
}

