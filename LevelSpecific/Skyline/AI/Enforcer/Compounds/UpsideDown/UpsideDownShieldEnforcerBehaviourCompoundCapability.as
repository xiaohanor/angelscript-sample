class UUpsideDownShieldEnforcerBehaviourCompoundCapability : UHazeCompoundCapability
{
	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;
	default CapabilityTags.Add(BasicAITags::CompoundBehaviour);	
	default CapabilityTags.Add(n"UpsideDown");	

	// Always active
	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (Owner.ActorUpVector.DotProduct(FVector::UpVector) > 0.7)
			return false;
		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (Owner.ActorUpVector.DotProduct(FVector::UpVector) > 0.6)
			return true;
		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		Owner.BlockCapabilitiesExcluding(BasicAITags::CompoundBehaviour, n"UpsideDown", this);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		Owner.UnblockCapabilities(BasicAITags::CompoundBehaviour, this);
	}

	UFUNCTION(BlueprintOverride)
	UHazeCompoundNode GenerateCompound()
	{
		return UHazeCompoundRunAll()
			.Add(UEnforcerShieldTrackBehaviour())
			.Add(UHazeCompoundSelector()
				// Stunned
				.Try(UHazeCompoundRunAll()
					.Add(UGravityBladeShieldReactionBehaviour())
					.Add(UGravityWhipThrowBehaviour())
					.Add(UGravityWhipGloryKillBehaviour())
					.Add(UGravityWhipLiftBehaviour())
					.Add(UGravityBladeHitReactionBehaviour())
					.Add(UBasicAIEntranceAnimationBehaviour())
				)
				// Combat
				.Try(UHazeCompoundRunAll()		
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

