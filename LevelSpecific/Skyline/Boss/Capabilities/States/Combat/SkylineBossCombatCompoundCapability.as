class USkylineBossCombatCompoundCapability : USkylineBossCompoundCapability
{
	default CapabilityTags.Add(SkylineBossTags::SkylineBossCombat);
	
	// After Assemble
	default TickGroupOrder = 110;

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if(Boss.IsStateActive(ESkylineBossState::Combat))
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if(!Boss.IsStateActive(ESkylineBossState::Combat))
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		Boss.SetState(ESkylineBossState::Combat);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		ResetCompoundNodes();
	}

	UFUNCTION(BlueprintOverride, Meta = (NoSuperCall))
	UHazeCompoundNode GenerateCompound()
	{
		return UHazeCompoundRunAll()
			// Movement
			.Add(UHazeCompoundRunAll()
				.Add(USkylineBossLegTargetableCapability())
				.Add(USkylineBossBodyMovementCapability())
				.Add(USkylineBossFootPlacementCapability())
				.Add(USkylineBossFeetSyncCapability())
				.Add(USkylineBossFootGroundedCapability())
				.Add(USkylineBossTargetCapability())
				.Add(USkylineBossLookAtCapability())
			)

			// Attacks
			.Add(UHazeCompoundRunAll()
				.Add(USkylineBossFootStompAttackCapability())
				.Add(USkylineBossFootPrintAttackCapability())
				.Add(UHazeCompoundStatePicker()
					//.State(USkylineBossSeekerMissileAttackCapability())
					.State(USkylineBossFocusBeamSweepAttackCapability())
//					.State(USkylineBossShockWaveAttackCapability())
//					.State(USkylineBossCarpetBombAttackCapability())
					.State(USkylineBossRocketBarrageAttackCapability())
					//.State(USkylineBossObeliskDropAttackCapability())
					//.State(USkylineBossFocusBeamAttackCapability())
				)
				//.Add(USkylineBossStrafeRunAttackCapability())
				//.Add(USkylineBossProximityMineAttackCapability())
				//.Add(USkylineBossShockWaveAttackCapability())
			)
		;
	}
}