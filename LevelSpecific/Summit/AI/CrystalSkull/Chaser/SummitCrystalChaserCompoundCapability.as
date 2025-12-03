class USummitCrystalChaserCompoundCapability : UHazeCompoundCapability
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
				.Add(USummitCrystalChaserAttackBehaviour())
				.Add(USummitCrystalSkullChaseBehaviour()) 
				.Add(USummitCrystalSkullTrackTargetBehaviour())					
				.Add(USummitCrystalSkullHoldingBehaviour())
				.Add(USummitCrystalChaserTargetingBehaviour());
	}
}
