class UIslandPunchotronBehaviourCompoundCapability : UHazeCompoundCapability
{
	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;
	default CapabilityTags.Add(BasicAITags::CompoundBehaviour);
	UPathfollowingSettings PathingSettings;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		PathingSettings = UPathfollowingSettings::GetSettings(Owner);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (PathingSettings.bIgnorePathfinding)
			return false;
		return true;
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		ResetCompoundNodes();
	}
	UFUNCTION(BlueprintOverride)
	UHazeCompoundNode GenerateCompound()
	{
		return UHazeCompoundRunAll()
					.Add(UHazeCompoundSelector()
						.Try(UIslandPunchotronCrowdRepulsionBehaviour())
					)
					.Add(UHazeCompoundSelector()						
						.Try(UIslandPunchotronStunnedReactionBehaviour())
						.Try(UHazeCompoundStatePicker()
							// .State(UHazeCompoundSequence()
							//  	.Then(UIslandPunchotronHaywireChargeAttackBehaviour())
							// )
							.State(UHazeCompoundSequence()
								.Then(UIslandPunchotronCobraStrikeAttackBehaviour())
							)
						)						
						.Try(UIslandPunchotronSwitchTargetOnDeathBehaviour())
						.Try(UIslandPunchotronOppositeColourSwitchTargetBehaviour())
						.Try(UHazeCompoundRunAll()
							.Add(UIslandPunchotronFollowSplineBehaviour())
							.Add(UIslandPunchotronProximityAttackBehaviour())
							.Add(UIslandPunchotronChaseBehaviour())							
						)
						.Try(UIslandPunchotronOppositeColourFindTargetBehaviour())
					)
				;
	}
}