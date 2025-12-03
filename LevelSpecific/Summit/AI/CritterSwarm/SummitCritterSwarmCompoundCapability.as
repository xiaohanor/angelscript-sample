class USummitCritterSwarmCompoundCapability : UHazeCompoundCapability
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
				.Add(USummitCritterSwarmSpawnBehaviour())
				.Add(USummitCritterSwarmGrabBallBehaviour())
				.Add(USummitCritterSwarmHurtRecoilBehaviour())					
				.Add(USummitCritterSwarmChaseBehaviour())
				.Add(USummitCritterSwarmGuardSplineBehaviour())					
				.Add(USummitCritterSwarmHoldingBehaviour());
	}
}