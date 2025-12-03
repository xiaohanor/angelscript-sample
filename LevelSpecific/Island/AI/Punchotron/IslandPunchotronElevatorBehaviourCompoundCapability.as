class UIslandPunchotronElevatorBehaviourCompoundCapability : UHazeCompoundCapability
{
	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;
	default CapabilityTags.Add(BasicAITags::CompoundBehaviour);
	UPathfollowingSettings PathingSettings;
	UIslandPunchotronAttackComponent AttackComp;
	UBasicAICharacterMovementComponent MoveComp;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		PathingSettings = UPathfollowingSettings::GetSettings(Owner);
		AttackComp = UIslandPunchotronAttackComponent::Get(Owner);
		MoveComp = UBasicAICharacterMovementComponent::Get(Owner);
	}

	// Always active
	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (!PathingSettings.bIgnorePathfinding)
			return false;
		return true;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		AttackComp.DisableAttack(EIslandPunchotronAttackState::HaywireAttack);
		AttackComp.NextAttackState();
		UMovementStandardSettings::SetAutoFollowGround(Owner, EMovementAutoFollowGroundType::FollowWalkable, this, EHazeSettingsPriority::Defaults);
		MoveComp.ApplyFollowEnabledOverride(this, EMovementFollowEnabledStatus::FollowEnabled);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		ResetCompoundNodes();
		UMovementStandardSettings::ClearAutoFollowGround(Owner, this);
		MoveComp.ClearFollowEnabledOverride(this);
	}

	UFUNCTION(BlueprintOverride)
	UHazeCompoundNode GenerateCompound()
	{
		return UHazeCompoundRunAll()
					.Add(UIslandPunchotronFindBalancedTargetBehaviour())
					.Add(UHazeCompoundSelector()
						.Try(UIslandPunchotronCrowdRepulsionBehaviour())
					)
					.Add(UHazeCompoundSelector()						
						.Try(UIslandPunchotronStunnedReactionBehaviour())
						.Try(UIslandPunchotronFallEntranceBehaviour())
						.Try(UHazeCompoundStatePicker()
							.State(UHazeCompoundSequence()
								.Then(UIslandPunchotronCobraStrikeAttackBehaviour())
							)
						)
						.Try(UIslandPunchotronSwitchTargetOnDeathBehaviour())
						.Try(UIslandPunchotronOppositeColourSwitchTargetBehaviour())
						.Try(UHazeCompoundRunAll()
							.Add(UIslandPunchotronFollowSplineBehaviour())
							.Add(UIslandPunchotronProximityAttackBehaviour())
							.Add(UHazeCompoundSelector()
								.Try(UIslandPunchotronElevatorChaseBehaviour())
								.Try(UBasicTrackTargetBehaviour())
							)
						)
						.Try(UIslandPunchotronOppositeColourFindTargetBehaviour())
					)
				;
	}
}