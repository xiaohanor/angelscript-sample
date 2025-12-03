class URappellerBehaviourCompoundCapability : UHazeCompoundCapability
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
					.Try(UHazeCompoundRunAll()
						.Add(USkylineRappellerGravityWhipThrowBehaviour())
						.Add(UGravityWhipLiftBehaviour())
						.Add(USkylineRappellerFallBehaviour())
						.Add(UGravityBladeHitReactionBehaviour())
					)
					.Try(USkylineEnforcerDeployBehaviour())
					.Try(UHazeCompoundRunAll()
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
							.State(UBasicFindProximityTargetBehaviour())
							.State(UBasicGentlemanQueueSwitcherBehaviour())
						)
						.Add(UBasicTrackTargetBehaviour())
						.Add(UBasicRaiseAlarmBehaviour())
					)
					.Try(UHazeCompoundRunAll()
						.Add(UEnforcerFindBalancedTargetBehaviour())
					);
	}
}

