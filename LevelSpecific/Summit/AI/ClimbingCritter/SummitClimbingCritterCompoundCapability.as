class USummitClimbingCritterCompoundCapability : UHazeCompoundCapability
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
		return UHazeCompoundRunAll()
			.Add(UBasicCrowdRepulsionBehaviour())
			.Add(UHazeCompoundSelector()
				.Try(
					USummitClimbingCritterKnockbackBehaviour()
				)
				// Comba
				.Try(UHazeCompoundRunAll()
					.Add(USummitClimbingCritterLatchOnBehaviour())
					.Add(UBasicCrowdEncircleBehaviour())
					.Add(USummitClimbingCritterChaseBehaviour())					
					.Add(UBasicTrackTargetBehaviour())
					.Add(UBasicRaiseAlarmBehaviour())									
				)
				.Try(UHazeCompoundRunAll()
					.Add(UBasicFindPriorityTargetBehaviour())
					.Add(UBasicFindBalancedTargetBehaviour())
					.Add(UBasicRoamBehaviour())
				)
			);
	}
}