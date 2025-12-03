class UIslandTentaclytronBehaviourCompoundCapability : UHazeCompoundCapability
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
				.Add(UHazeCompoundSelector()
					.Try(UBasicScenepointEntranceBehaviour())
					.Try(UHazeCompoundRunAll()
						.Add(UIslandTentaclytronDamageReactionBehaviour())
						.Add(UHazeCompoundSelector()
							.Try(UIslandTentaclytronChaseBehaviour())							
						)
						.Add(UBasicFindProximityTargetBehaviour())
					)
					.Try(UHazeCompoundRunAll()
						.Add(UBasicFindBalancedTargetBehaviour())
					)
				);
	}
}
