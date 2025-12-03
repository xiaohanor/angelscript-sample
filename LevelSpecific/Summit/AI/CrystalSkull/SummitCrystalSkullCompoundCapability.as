class USummitCrystalSkullCompoundCapability : UHazeCompoundCapability
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
					.State(UHazeCompoundSequence()
						.Then(USummitCrystalSkullArcAttackBehaviour())
						.Then(USummitCrystalSkullRecoverBehaviour())
					) 
				)
				.Add(USummitCrystalSkullEvadeBehaviour()) 
				.Add(USummitCrystalSkullTrackTargetBehaviour())					
				.Add(USummitCrystalSkullHoldingBehaviour())
				.Add(USummitCrystalSkullTargetingBehaviour());
	}
}
