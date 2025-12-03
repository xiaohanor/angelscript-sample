class UStaticEnforcerBehaviourCompoundCapability : UHazeCompoundCapability
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
						//.Add(UBasicBehaviourKnockdown())
						.Add(UGravityWhipStumbleBehaviour())
						.Add(UGravityBladeHitReactionBehaviour())
						.Add(UBasicAIEntranceAnimationBehaviour())
					)
					// Combat
					.Try(UHazeCompoundRunAll()
						.Add(UEnforcerTraversalEntranceBehaviour())
						.Add(UEnforcerTraverseToScenepointEntranceBehaviour())
						.Add(UHazeCompoundStatePicker()
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
							.State(UEnforcerFindProximityTargetBehaviour())
							.State(UBasicGentlemanQueueSwitcherBehaviour())
						)
						.Add(UBasicTrackTargetBehaviour())
						.Add(UBasicRaiseAlarmBehaviour())
					)
					// Idle
					.Try(UHazeCompoundRunAll()
						.Add(UEnforcerFindBalancedTargetBehaviour())
						.Add(UBasicScenepointEntranceBehaviour())
					);
	}
}

