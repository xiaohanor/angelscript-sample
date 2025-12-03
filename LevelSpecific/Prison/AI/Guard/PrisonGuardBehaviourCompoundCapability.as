class UPrisonGuardBehaviourCompoundCapability : UHazeCompoundCapability
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
				.Add(UPrisonGuardMagneticBurstStunnedBehaviour())
				.Add(UPrisonGuardHitByDroneBehaviour())
				.Add(UHazeCompoundSelector()
					.Try(UHazeCompoundRunAll()
						.Add(UHazeCompoundStatePicker()
							.State(UPrisonGuardAttackBehaviour())
						)				
						.Add(UBasicFitnessCircleStrafeBehaviour())
						.Add(UPrisonGuardChaseBehaviour())
						.Add(UPrisonGuardTrackTargetBehaviour())
					)
				)
				.Add(UPrisonGuardTargetingBehaviour())
				.Add(UPrisonGuardIdleBehaviour())
			);
	}
}