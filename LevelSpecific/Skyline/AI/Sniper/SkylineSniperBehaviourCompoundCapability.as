class USkylineSniperBehaviourCompoundCapability : UHazeCompoundCapability
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
		return 	UHazeCompoundSelector()
					.Try(UHazeCompoundRunAll()
						.Add(UGravityWhipThrowBehaviour())
						.Add(UGravityWhipGloryKillBehaviour())
						.Add(UGravityWhipLiftBehaviour())
						.Add(UGravityBladeHitReactionBehaviour())
					)
					.Try(UBasicFallingBehaviour())
					.Try(USkylineEnforcerDeployBehaviour())
					.Try(UHazeCompoundRunAll()
						.Add(UHazeCompoundStatePicker()
							.State(UHazeCompoundSequence()
								.Then(USkylineSniperSniperAimingBehaviour())
								.Then(USkylineSniperSniperAttackBehaviour())
							)
							.State(UBasicGentlemanQueueSwitcherBehaviour())
						)
						.Add(UBasicTrackTargetBehaviour())
						.Add(UBasicRaiseAlarmBehaviour())
					)
					.Try(UHazeCompoundRunAll()
						.Add(UEnforcerFindBalancedTargetBehaviour())
						.Add(UBasicScenepointEntranceBehaviour())
					);
	}
}

