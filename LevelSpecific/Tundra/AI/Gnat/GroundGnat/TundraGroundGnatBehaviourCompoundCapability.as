class UTundraGroundGnatBehaviourCompoundCapability : UHazeCompoundCapability
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
					.Try(UBasicSplineEntranceBehaviour())
					.Try(UTundraGnatShakenOffBehaviour())
					.Try(UTundraGnatStartingTauntBehaviour())
					.Try(UTundraGroundGnatAnnoyBehaviour())
					.Try(UTundraGroundGnatPatrolBehaviour())
					.Try(UTundraGroundGnatEngageBehaviour())
					.Try(UBasicFindBalancedTargetBehaviour())
				);
	}
}
