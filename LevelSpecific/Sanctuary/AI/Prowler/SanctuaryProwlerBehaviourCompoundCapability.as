// Generic melee enemy behaviour
class USanctuaryProwlerBehaviourCompoundCapability : UHazeCompoundCapability
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
						.Add(UBasicHurtReactionBehaviour())
					)
					// Combat
					.Try(UHazeCompoundRunAll()
						.Add(UHazeCompoundStatePicker()
							.State(USanctuaryProwlerAttackBehaviour())
							.State(UBasicFindProximityTargetBehaviour())
							.State(UBasicGentlemanQueueSwitcherBehaviour())
						)
						.Add(UBasicFitnessCircleStrafeBehaviour())
						.Add(UBasicChaseBehaviour())
						.Add(UBasicTrackTargetBehaviour())
						.Add(UBasicRaiseAlarmBehaviour())
					)
					.Try(UHazeCompoundRunAll()
						.Add(UBasicFindPriorityTargetBehaviour())
						.Add(UBasicFindBalancedTargetBehaviour())	
					);
	}
}

