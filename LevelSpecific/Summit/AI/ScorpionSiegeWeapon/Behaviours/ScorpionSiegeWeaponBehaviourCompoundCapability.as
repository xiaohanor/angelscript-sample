class UScorpionSiegeWeaponBehaviourCompoundCapability : UHazeCompoundCapability
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
						.Add(UScorpionSiegeWeaponDestroyedBehaviour())
						.Add(UScorpionSiegeWeaponUnoperationalBehaviour())
						.Add(UBasicHurtReactionBehaviour())
					)
					// Combat
					.Try(UHazeCompoundRunAll()
						.Add(UHazeCompoundStatePicker()
							.State(UScorpionSiegeWeaponAttackBehaviour())
							.State(UBasicFindProximityTargetBehaviour())
						)
						.Add(UScorpionSiegeWeaponAimingBehaviour())
						.Add(UBasicTrackTargetBehaviour())		
						.Add(UBasicRaiseAlarmBehaviour())
					)
					// Idle
					.Try(UHazeCompoundRunAll()
						.Add(UBasicFindBalancedTargetBehaviour())
					);
	}
}

