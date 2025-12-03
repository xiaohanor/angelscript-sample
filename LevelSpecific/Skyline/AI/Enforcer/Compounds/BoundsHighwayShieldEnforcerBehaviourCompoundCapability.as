class UBoundsHighwayShieldEnforcerBehaviourCompoundCapability : UHazeCompoundCapability
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
		return 	UHazeCompoundRunAll()
			.Add(UEnforcerShieldTrackBehaviour())
			.Add(UHazeCompoundSelector()
					.Try(UHazeCompoundRunAll()
						.Add(UGravityBladeShieldReactionBehaviour())
						.Add(UGravityWhipThrowBehaviour())
						.Add(UGravityWhipGloryKillBehaviour())
						.Add(UGravityWhipLiftBehaviour())
						.Add(UGravityWhipStumbleBehaviour())
						.Add(UHighwayGravityBladeHitReactionBehaviour())
						.Add(UBasicAIEntranceAnimationBehaviour())
					)
					.Try(USkylineEnforcerScenepointEntranceBehaviour())
					.Try(UBasicFallingBehaviour())
					.Try(USkylineEnforcerDeployBehaviour())
					.Try(UHazeCompoundRunAll()
						.Add(USkylineEnforcerBoundsCrowdRepulsionBehaviour())
						.Add(UHazeCompoundSelector()
							.Try(UHazeCompoundRunAll()
								.Add(UEnforcerPreventCombatMovementBehaviour())
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
							))));
	}
}

