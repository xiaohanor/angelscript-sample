class USummitCrystalSkullArmouredCompoundCapability : UHazeCompoundCapability
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
				.Add(UHazeCompoundStatePicker()
					.State(USummitCrystalSkullSpawnCrittersBehaviour())
					.State(USummitCrystalSkullDeployShieldsBehaviour())
				)
				.Add(USummitCrystalSkullTrackTargetBehaviour())					
				.Add(USummitCrystalSkullHoldingBehaviour())
				.Add(USummitCrystalSkullTargetingBehaviour());
	}
}