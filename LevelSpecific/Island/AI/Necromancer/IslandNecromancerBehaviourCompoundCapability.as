class UIslandNecromancerBehaviourCompoundCapability : UHazeCompoundCapability
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
		return UHazeCompoundSelector()
			.Try(UHazeCompoundRunAll()
				.Add(UIslandPushKnockBehaviour())
				.Add(UHazeCompoundStatePicker()
					.State(UIslandZombieWallDeathBehaviour())
					.State(UIslandZombiePitDeathBehaviour())
					.State(UIslandZombieLaunchDeathBehaviour())
					.State(UIslandZombieDefaultDeathBehaviour())
				)				
			)
			.Try(UHazeCompoundRunAll()
				.Add(UBasicCrowdRepulsionBehaviour())
				.Add(UHazeCompoundSelector()
					.Try(UHazeCompoundRunAll()
						.Add(UIslandNecromancerReviveBehaviour())
						.Add(UBasicFindProximityTargetBehaviour())
						.Add(UBasicEvadeBehaviour())						
						.Add(UBasicFitnessCircleStrafeBehaviour())						
						.Add(UBasicChaseBehaviour())						
						.Add(UBasicTrackTargetBehaviour())
					)
					.Try(UHazeCompoundRunAll()
						.Add(UBasicFindBalancedTargetBehaviour())
						.Add(UBasicRoamBehaviour())
					)));
	}
}