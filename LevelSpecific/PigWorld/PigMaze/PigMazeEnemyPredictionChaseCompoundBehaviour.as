class UPigMazeEnemyPredictionChaseBehaviourCompoundCapability : UHazeCompoundCapability
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
				.Add(UHazeCompoundSelector()
					.Try(UHazeCompoundRunAll()
						.Add(UBasicFindProximityTargetBehaviour())			
						.Add(UPigMazeEnemyPredictionChaseBehaviour())
						.Add(UBasicTrackTargetBehaviour())
					)
					.Try(UHazeCompoundRunAll()
						.Add(UBasicFindBalancedTargetBehaviour())
					)));
	}
}