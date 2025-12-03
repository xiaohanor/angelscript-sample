class USkylineBossFlyingPhaseCompoundCapability : UHazeCompoundCapability
{
	default NetworkMode = EHazeCapabilityNetworkMode::Local;
	default CapabilityTags.Add(BasicAITags::CompoundBehaviour);

	default TickGroup = EHazeTickGroup::Gameplay;
	default TickGroupOrder = 102;

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
			// States
			.Add(UHazeCompoundSelector()
				.Try(UHazeCompoundRunAll()
					// Move
					.Add(UHazeCompoundRunAll()
						.Add(USkylineBossFlyingChaseCapability())
						.Add(USkylineBossFlyingLaserCapability())
					)
					// Attack
					.Add(UHazeCompoundRunAll()
						.Add(UHazeCompoundStatePicker()
							//.State(USkylineBossSeekerMissileAttackCapability())
							//.State(USkylineBossFocusBeamSweepAttackCapability())
//							.State(USkylineBossShockWaveAttackCapability())
							//.State(USkylineBossCarpetBombAttackCapability())
							//.State(USkylineBossObeliskDropAttackCapability())
							//.State(USkylineBossFocusBeamAttackCapability())
						)
					//	.Add(USkylineBossStrafeRunAttackCapability())
					//	.Add(USkylineBossProximityMineAttackCapability())
					//	.Add(USkylineBossShockWaveAttackCapability())
					)
				)
			)
			//.Add(USkylineBossTargetCapability())
		;
	}
}