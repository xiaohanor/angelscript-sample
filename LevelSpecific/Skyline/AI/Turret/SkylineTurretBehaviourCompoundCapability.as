class USkylineTurretBehaviourCompoundCapability : UHazeCompoundCapability
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
			.Add(UHazeCompoundSelector()
				.Try(UHazeCompoundRunAll()
					.Add(UHazeCompoundSelector()
						.Try(USkylineTurretSweepAttackBehaviour())
						.Try(USkylineTurretAttackBehaviour())
					)
					.Add(USkylineTurretTrackTargetBehaviour())
				)
			);
	}
}