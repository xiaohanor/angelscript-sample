class USummitMageCompoundCapability : UHazeCompoundCapability
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
				.Add(USummitMageModeBlockerBehaviour())
				.Add(UHazeCompoundSelector()
					// Knockdown
					.Try(UHazeCompoundRunAll()
						.Add(USummitKnockdownBehaviour())						
					)
					// Combat
					.Try(UHazeCompoundRunAll()						
						.Add(USummitMageTraversalTeleportBehaviour())
						.Add(UHazeCompoundStatePicker()						
							.State(USummitMageCritterSlugBehaviour())
							.State(USummitMageDonutBehaviour())
							.State(USummitMageSpiritBallBehaviour())
							.State(UBasicFindProximityTargetBehaviour())
							.State(UBasicGentlemanQueueSwitcherBehaviour())
						)		
						.Add(USummitMageGentlemanCircleCapability())
						// .Add(UBasicFitnessCircleStrafeBehaviour()) Don't use fitness behaviours on a TopDown enemy						
						.Add(UBasicTrackTargetBehaviour())
						.Add(UBasicRaiseAlarmBehaviour())
					)
					.Try(UHazeCompoundRunAll()
						.Add(UBasicFindPriorityTargetBehaviour())
						.Add(UBasicFindBalancedTargetBehaviour())
					));
	}
}