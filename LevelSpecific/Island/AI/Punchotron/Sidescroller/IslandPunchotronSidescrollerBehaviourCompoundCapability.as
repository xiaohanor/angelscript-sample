class UIslandPunchotronSidescrollerBehaviourCompoundCapability : UHazeCompoundCapability
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
					// .Add(UHazeCompoundSelector()						
					// 	.Try(UIslandPunchotronCrowdRepulsionBehaviour())
					// )
					.Add(UIslandPunchotronFindBalancedTargetBehaviour())
					.Add(UIslandPunchotronSidescrollerStunnedReactionBehaviour())
					.Add(UHazeCompoundSelector()						
						.Try(UIslandPunchotronSidescrollerFallEntranceBehaviour())
						.Try(UHazeCompoundStatePicker()
							.State(UIslandPunchotronLeapTraversalChaseBehaviour())
							.State(UHazeCompoundSelector()
								.Try(UIslandPunchotronSidescrollerKickAttackBehaviour())
								.Try(UIslandPunchotronSidescrollerHaywireAttackBehaviour())
								.Try(UIslandPunchotronSidescrollerCobraStrikeAttackBehaviour())
								//.Try(UIslandPunchotronSidescrollerSpinningAttackBehaviour())
							)
						)
						.Try(UIslandPunchotronSwitchTargetOnDeathBehaviour())
						.Try(UHazeCompoundRunAll()
							.Add(UBasicChaseBehaviour())							
							.Add(UBasicTrackTargetBehaviour())
						)
					)
				;
	}
}