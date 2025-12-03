class USmasherBehaviourCompoundCapability : UHazeCompoundCapability
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
				.Add(UHazeCompoundSelector()
					.Try(UBasicAIEntranceAnimationBehaviour())
					// Stunned
					.Try(UHazeCompoundRunAll()
						.Add(UBasicHurtReactionBehaviour())
					)
					// Combat
					.Try(UHazeCompoundRunAll()
						.Add(USummitSmasherTraversalTeleportBehaviour())
						.Add(UHazeCompoundStatePicker()
							.State(USmasherJumpAttackBehaviour())
							.State(USmasherAttackBehaviour())
							.State(UBasicFindProximityTargetBehaviour())
							.State(UBasicGentlemanQueueSwitcherBehaviour())
						)
						.Add(UBasicCrowdEncircleBehaviour())						
						.Add(UBasicChaseBehaviour())
						.Add(UBasicEvadeBehaviour())
						.Add(UBasicTrackTargetBehaviour())
						.Add(UBasicRaiseAlarmBehaviour())
					)
					.Try(UHazeCompoundRunAll()
						.Add(UBasicFindPriorityTargetBehaviour())
						.Add(UBasicFindBalancedTargetBehaviour())	
					));
	}
}

