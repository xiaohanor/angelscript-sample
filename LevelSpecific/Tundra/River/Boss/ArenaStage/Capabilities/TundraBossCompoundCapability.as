// class UTundraBossCompoundCapability : UHazeCompoundCapability
// {
// 	default CapabilityTags.Add(n"TundraBossCompound");
// 	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;

// 	UFUNCTION(BlueprintOverride)
// 	UHazeCompoundNode GenerateCompound()
// 	{
// 		return UHazeCompoundRunAll()
// 			.Add(UHazeCompoundStatePicker()
// 				.State(UTundraBossSpawnCapability())
// 				.State(UTundraBossDefeatedCapability())
// 				.State(UTundraBossSpawnLastPhaseCapability())
// 				.State(UTundraBossReturnAfterFirstSphereHitCapability())
// 				.State(UTundraBossHiddenCapability())
// 				.State(UTundraBossTakePunchDamageCapability())
// 				.State(UTundraBossTakeSphereDamageCapability())
// 				.State(UTundraBossGrabbedCapability())
// 				.State(UTundraBossBreakFreeCapability())
// 				.State(UTundraBossBreakFreeFromStruggleCapability())
// 				.State(UTundraBossGetBackUpFromSphereCapability())
// 				.State(UTundraBossCloseAttackCapability())
// 				.State(UTundraBossWaitCapability())
// 				.State(UTundraBossWaitUnlimitedCapability())
// 				.State(UTundraBossJumpToLocationCapability())
// 				.State(UTundraBossClawAttackCapability())
// 				.State(UTundraBossRingOfIceSpikesCapability())
// 				.State(UTundraBossChargeCapability())
// 				.State(UTundraBossFallingIceSpikeCapability())
// 				.State(UTundraBossFallingRedIceCapability())
// 				.State(UTundraBossBreakingIceCapability())
// 				.State(UTundraBossFurBallCapability())
// 				.State(UTundraBossFurBallUnlimitedCapability())
// 				.State(UTundraBossStopFurballCapability())
// 				.State(UTundraBossWhirlwindCapability())
// 				.State(UTundraBossStopFallingIceSpikeCapability())
// 				.State(UTundraBossStopRedIceCapability())
// 				.State(UTundraBossFinalPunchCapability())
// 			);
// 	}

// 	UFUNCTION(BlueprintOverride)
// 	bool ShouldActivate() const
// 	{
// 		return true;
// 	}

// 	UFUNCTION(BlueprintOverride)
// 	bool ShouldDeactivate() const
// 	{
// 		return false;
// 	}
// };