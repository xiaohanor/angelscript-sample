class USummitFlyingCritterCompoundCapability : UHazeCompoundCapability
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
					USummitFlyingCritterKnockbackBehaviour()
				)
				// Combat
				.Try(UHazeCompoundRunAll()
					.Add(UHazeCompoundSelector()
						.Try(USummitFlyingCritterAttackBehaviour())
						)		
					.Add(UBasicFlyingCrowdEncircleBehaviour())
					.Add(UBasicFlyingChaseBehaviour())					
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