class UCoastTrainDroneBehaviourCompoundCapability : UHazeCompoundCapability
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
				.Add(UCoastTrainDroneDamageReactionBehaviour())
				.Add(UBasicCrowdRepulsionBehaviour())
				.Add(UHazeCompoundSelector()
					.Try(UCoastTrainDroneScanZapAttackBehaviour())
					.Try(UCoastTrainDroneScanCartBehaviour())
					.Try(UCoastTrainDroneHoldAtCartBehaviour())
					)
				;
	}
}
