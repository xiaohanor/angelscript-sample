class UPrisonGuardBotZapperBehaviourCompoundCapability : UHazeCompoundCapability
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
				.Add(UBasicSplineEntranceBehaviour())
				.Add(UBasicCrowdRepulsionBehaviour())
				.Add(UPrisonGuardBotHitReactionBehaviour())
				.Add(UPrisonGuardBotZapAttackBehaviour())			
				.Add(UPrisonGuardBotZapperChaseBehaviour())
				.Add(UBasicFlyingCircleStrafeBehaviour())
				.Add(UBasicTrackTargetBehaviour())
				.Add(UPrisonGuardBotZapperTargetingBehaviour())
				;
	}
}
