class UBoundsHighwayEnforcerBehaviourCompoundCapability : UHazeCompoundCapability
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
		if(BoundsComp.CurrentBounds == nullptr)
			return false;
		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if(BoundsComp.CurrentBounds == nullptr)
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
						.Add(UHighwayGravityBladeHitReactionBehaviour())
						.Add(UBasicAIEntranceAnimationBehaviour())
					)
					.Try(USkylineEnforcerScenepointEntranceBehaviour())
					.Try(UEnforcerTraversalChaseBehaviour())
					.Try(UBasicFallingBehaviour())
					.Try(USkylineEnforcerDeployBehaviour())
					.Try(UHazeCompoundRunAll()
						.Add(USkylineEnforcerBoundsCrowdRepulsionBehaviour())
						.Add(UHazeCompoundSelector()
							.Try(UHazeCompoundRunAll()
								.Add(UEnforcerPreventCombatMovementBehaviour())
								.Add(UHazeCompoundStatePicker()
									.State(UEnforcerGrenadeAttackBehaviour())
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
								.Add(UHighwayEnforcerEvadeBehaviour())											
								.Add(UHighwayEnforcerFitnessCircleStrafeBehaviour())						
								.Add(UHighwayEnforcerChaseBehaviour())
								.Add(UHighwayEnforcerShuffleBehaviour())
								.Add(UBasicTrackTargetBehaviour())
								.Add(UBasicRaiseAlarmBehaviour())
							)
							// Idle
							.Try(UHazeCompoundRunAll()
								.Add(UEnforcerFindPriorityTargetBehaviour())
								.Add(UEnforcerFindBalancedTargetBehaviour())
								.Add(UBasicScenepointEntranceBehaviour())
							)));
	}
}

