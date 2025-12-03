class UCoastWaterJetCompoundCapability : UHazeCompoundCapability
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
				.Add(UCoastWaterJetDamageReactionBehaviour()) 
				.Add(UCoastWaterJetTargetingBehaviour()) 
				// .Add(UCoastWaterJetAttackBehaviour())
				.Add(UCoastWaterJetGrenadeAttackBehaviour())
				// .Add(UCoastWaterJetChaseBehaviour()) 
			;
	}
}
