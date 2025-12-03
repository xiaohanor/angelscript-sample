class USummitDecimatorSpikeBombBehaviourCompoundCapability : UHazeCompoundCapability
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
				.Try(UHazeCompoundRunAll()
					.Add(USummitDecimatorSpikeBombImpactDetonateBehaviour())
					.Add(USummitDecimatorSpikeBombPlayerImpactDetonateBehaviour())
					.Add(USummitDecimatorSpikeBombSelfDetonateBehaviour())
				)
				.Try(UHazeCompoundSelector()
					.Try(USummitDecimatorSpikeBombFallingBehaviour())
					.Try(USummitDecimatorSpikeBombIdleBehaviour())
					.Try(USummitDecimatorSpikeBombChaseBehaviour())
					.Try(UBasicFindTargetBehaviour())
				);
	}
}


