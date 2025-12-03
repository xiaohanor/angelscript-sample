class UCoastBomblingBehaviourCompoundCapability : UHazeCompoundCapability
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
					.Try(UBasicSplineEntranceBehaviour())
					.Try(UHazeCompoundRunAll()
						.Add(UCoastBomblingProximityExplosionBehaviour())
						.Add(UBasicFindProximityTargetBehaviour())
						.Add(UHazeCompoundSelector()
							.Try(UCoastBomblingChaseBehaviour())
							.Try(UCoastBomblingStrafeBehaviour())
							.Try(UCoastBomblingEvadeBehaviour())
						)
						.Add(UBasicTrackTargetBehaviour())
					).Try(UHazeCompoundRunAll()
						.Add(UCoastBomblingFindTargetBehaviour())
					);
	}
}

