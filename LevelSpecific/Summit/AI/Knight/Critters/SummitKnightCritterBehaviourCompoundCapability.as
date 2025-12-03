class USummitKnightCritterBehaviourCompoundCapability : UHazeCompoundCapability
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
						.Try(UBasicAIEntranceAnimationBehaviour())
						.Try(USummitKnightCritterKnockbackBehaviour())
						.Try(UHazeCompoundRunAll()
							.Add(USummitKnightCritterLatchOnBehaviour())
							.Add(UBasicCrowdEncircleBehaviour())
							.Add(USummitKnightCritterChaseBehaviour())
							.Add(USummitKnightCritterRoamBehaviour())
							.Add(UBasicTrackTargetBehaviour())
						)
					)
		   		;
	}
}
