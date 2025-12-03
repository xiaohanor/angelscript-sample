class UScorpionSiegeOperatorBehaviourCompoundCapability : UHazeCompoundCapability
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
					// Operating weapon
					.Try(
						UHazeCompoundRunAll()
						.Add(UScorpionSiegeOperatorOperatingWeaponBehaviour())
					)
					// Stunned
					.Try(UHazeCompoundRunAll()
						.Add(UBasicKnockdownBehaviour())
						.Add(UBasicHurtReactionBehaviour())
					)
					// Approach weapon
					.Try(
						UHazeCompoundRunAll()
						.Add(UScorpionSiegeOperatorRepairWeaponBehaviour())
						.Add(UScorpionSiegeOperatorApproachWeaponBehaviour())
					)
					// Combat
					.Try(
						UHazeCompoundRunAll()
						.Add(UScorpionSiegeOperatorFindWeaponBehaviour())
						.Add(UBasicFindBalancedTargetBehaviour())
						.Add(UHazeCompoundStatePicker()
							.State(UScorpionSiegeOperatorAttackBehaviour())
							.State(UBasicFindProximityTargetBehaviour())
						)
						.Add(UBasicEvadeBehaviour())											
						.Add(UBasicCircleStrafeBehaviour())						
						.Add(UBasicChaseBehaviour())
						.Add(UBasicGentlemanCircleBehaviour())
						.Add(UBasicTrackTargetBehaviour())
						.Add(UBasicRaiseAlarmBehaviour())
					)
					// Idle
					.Try(UHazeCompoundRunAll()						
						.Add(UBasicScenepointEntranceBehaviour())
						.Add(UBasicRoamBehaviour())
					);
	}
}

