class UIslandTurretBehaviourCompoundCapability : UHazeCompoundCapability
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
			.Add(UIslandTurretExposeHackBehaviour())
			.Add(UIslandTurretHackedBehaviour())
			.Add(UHazeCompoundSelector()
				.Try(UHazeCompoundRunAll()
					.Add(UHazeCompoundSelector()
						.Try(UHazeCompoundRunAll()
							.Add(UIslandTurretAttackBehaviour())
							.Add(UIslandTurretTrackTargetBehaviour())
						)
						.Try(UHazeCompoundRunAll()
							.Add(UIslandTurretHackedFindTargetBehaviour())
							.Add(UBasicFindBalancedTargetBehaviour())
						)
					)
				)
			);
	}
}