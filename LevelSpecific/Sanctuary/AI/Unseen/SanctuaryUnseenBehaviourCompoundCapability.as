class USanctuaryUnseenBehaviourCompoundCapability : UHazeCompoundCapability
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
		return UHazeCompoundSelector()
			.Try(UHazeCompoundRunAll()
				.Add(UHazeCompoundSelector()
					.Try(USanctuaryUnseenNavMeshBehaviour())
					.Try(UHazeCompoundRunAll()						
						.Add(USanctuaryUnseenAttackBehaviour())
						.Add(USanctuaryUnseenChaseBehaviour())
					)
					.Try(UHazeCompoundRunAll()
						.Add(UBasicFindBalancedTargetBehaviour())
					)));
	}
}