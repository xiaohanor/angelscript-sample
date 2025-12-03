class USummitBallFlyerCompoundCapability : UHazeCompoundCapability
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
				.Add(UBasicCrowdRepulsionBehaviour())
				.Add(USummitBallFlyerHurtRecoilBehaviour())
				.Add(USummitBallFlyerAttackBehaviour())
				.Add(USummitBallFlyerChaseBehaviour())
				.Add(USummitBallFlyerGuardSplineBehaviour())
				.Add(USummitBallFlyerHoldingBehaviour())
				;
	}
}
