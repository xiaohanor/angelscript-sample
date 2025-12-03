
class UPlayerSprintActivateCapability : UHazePlayerCapability
{
	default CapabilityTags.Add(CapabilityTags::Movement);
	default CapabilityTags.Add(CapabilityTags::GameplayAction);	
	default CapabilityTags.Add(PlayerMovementTags::CoreMovement);
	default CapabilityTags.Add(PlayerMovementTags::Sprint);

	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;

	default DebugCategory = n"Movement";
	
	default TickGroup = EHazeTickGroup::BeforeMovement;
	default TickGroupOrder = 100;

	UPlayerSprintComponent SprintComp;
	UPlayerFloorMotionComponent FloorMotionComp;
	UPlayerMovementComponent MoveComp;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		SprintComp = UPlayerSprintComponent::GetOrCreate(Player);
		FloorMotionComp = UPlayerFloorMotionComponent::GetOrCreate(Player);
		MoveComp = UPlayerMovementComponent::Get(Player);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (SprintComp.IsSprintToggled())
			return false;

		// if(MoveComp.IsInAir())
		// 	return false;

		// if(MoveComp.HorizontalVelocity.Size() > SprintComp.Settings.MaximumSpeed && !MoveComp.MovementInput.IsNearlyZero())
		// 	return true;

		if(!WasActionStarted(ActionNames::MovementSprint))
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		return true;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		SprintComp.SetSprintToggled(true);
		Player.ConsumeButtonInputsRelatedTo(ActionNames::MovementSprint);

	}

};