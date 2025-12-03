
class UPlayerSprintDeactivateCapability : UHazePlayerCapability
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
	UPlayerGrappleComponent GrappleComp;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		SprintComp = UPlayerSprintComponent::GetOrCreate(Player);
		FloorMotionComp = UPlayerFloorMotionComponent::GetOrCreate(Player);
		MoveComp = UPlayerMovementComponent::Get(Player);
		GrappleComp = UPlayerGrappleComponent::Get(Player);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate(FSprintDeactivationParams& ActivationParams) const
	{
		if (!SprintComp.IsSprintToggled())
			return false;

		// We don't turn off sprint until we hit the ground with low velocity/no input
		if (!MoveComp.IsOnWalkableGround() && !MoveComp.HasCustomMovementStatus(n"Perching"))
			return false;
		
		// We dont turn off sprint if we are currently performing a grapple move
		if (GrappleComp.Data.GrappleState != EPlayerGrappleStates::Inactive)
			return false;

		if (MoveComp.MovementInput.IsNearlyZero())
			return true;

		if (MoveComp.HorizontalVelocity.Size() < FloorMotionComp.Settings.MinimumSpeed && !Player.IsAnyCapabilityActive(PlayerMovementTags::Sprint))
			return true;

		if(WasActionStarted(ActionNames::MovementSprint))
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		return true;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FSprintDeactivationParams ActivationParams)
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

struct FSprintDeactivationParams
{
	bool bToggledOffWhileMoving = false;
}