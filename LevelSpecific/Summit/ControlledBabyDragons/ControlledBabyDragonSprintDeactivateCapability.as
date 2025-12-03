class UControlledBabyDragonSprintDeactivateCapability : UHazePlayerCapability
{
	default CapabilityTags.Add(CapabilityTags::Movement);
	default CapabilityTags.Add(CapabilityTags::GameplayAction);	
	default CapabilityTags.Add(PlayerMovementTags::CoreMovement);
	default CapabilityTags.Add(PlayerMovementTags::Sprint);

	default DebugCategory = n"Movement";

	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;
	
	default TickGroup = EHazeTickGroup::BeforeMovement;
	default TickGroupOrder = 99;

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
	bool ShouldActivate(FControlledBabyDragonSprintDeactivationParams& ActivationParams) const
	{
		if (!SprintComp.IsSprintToggled())
			return false;

		if (MoveComp.MovementInput.IsNearlyZero())
			return true;

		if (MoveComp.HorizontalVelocity.Size() < ControlledBabyDragon::MinMoveSpeed && !Player.IsAnyCapabilityActive(PlayerMovementTags::Sprint))
			return true;

		if (WasActionStarted(ActionNames::MovementSprint) && SprintComp.IsSprintToggled())
		{
			ActivationParams.bToggledOffWhileMoving = true;
			return true;
		}

		return false;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		return true;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FControlledBabyDragonSprintDeactivationParams ActivationParams)
	{
		SprintComp.SetSprintToggled(false);
		Player.ConsumeButtonInputsRelatedTo(ActionNames::MovementSprint);

		if(ActivationParams.bToggledOffWhileMoving)
			SprintComp.bSprintToggledOffWhileMoving = true;

	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		SprintComp.bSprintToggledOffWhileMoving = false;
	}

};

struct FControlledBabyDragonSprintDeactivationParams
{
	bool bToggledOffWhileMoving = false;
}