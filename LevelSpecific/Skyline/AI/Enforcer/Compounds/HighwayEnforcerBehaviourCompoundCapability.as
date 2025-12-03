class UHighwayEnforcerBehaviourCompoundCapability : UHazeCompoundCapability
{
	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;
	default CapabilityTags.Add(BasicAITags::CompoundBehaviour);	

	USkylineEnforcerBoundsComponent BoundsComp;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		BoundsComp = USkylineEnforcerBoundsComponent::GetOrCreate(Owner);
	}

	// Always active
	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if(BoundsComp.CurrentBounds != nullptr)
			return false;
		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if(BoundsComp.CurrentBounds != nullptr)
			return true;
		return false;
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
					.Try(USkylineEnforcerScenepointEntranceBehaviour())
					.Try(UEnforcerTraversalChaseBehaviour())
					.Try(UBasicFallingBehaviour())
					.Try(USkylineEnforcerDeployBehaviour())
					.Try(UHazeCompoundRunAll()
						.Add(UBasicCrowdRepulsionBehaviour())
						.Add(UHazeCompoundSelector()
							.Try(UHazeCompoundRunAll()
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
									.State(UHazeCompoundSequence()
										.Then(UEnforcerGloveAttackBehaviour())
										.Then(UEnforcerWeaponRecoveryBehaviour())
									)
									.State(UEnforcerFindProximityTargetBehaviour())
									.State(UEnforcerGentlemanFitnessQueueSwitcherBehaviour())
								)
								// .Add(UEnforcerEvadeBehaviour())											
								// .Add(UBasicFitnessCircleStrafeBehaviour())						
								// .Add(UEnforcerChaseBehaviour())
								.Add(UBasicShuffleBehaviour())
								.Add(UBasicTrackTargetBehaviour())
								.Add(UBasicRaiseAlarmBehaviour())
							)
							// Idle
							.Try(UHazeCompoundRunAll()
								.Add(UEnforcerFindPriorityTargetBehaviour())
								.Add(UEnforcerFindBalancedTargetBehaviour())
								.Add(UBasicScenepointEntranceBehaviour())
							)
						)
					)
				;
	}
}

