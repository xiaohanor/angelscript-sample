class USummitCrystalSkullBossCompoundCapability : UHazeCompoundCapability
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
					.State(USummitCrystalSkullBossForceFieldBehaviour())
					.State(USummitCrystalSkullDeployShieldsBehaviour())
					.State(USummitCrystalSkullArcAttackBehaviour()) 
				)
				.Add(USummitCrystalSkullHoldingBehaviour())
				.Add(USummitCrystalSkullTrackTargetBehaviour())					
				.Add(USummitCrystalSkullTargetingBehaviour());
	}
}
