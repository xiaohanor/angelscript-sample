class UPinballMagnetJumpCapability : UHazePlayerCapability
{
	default NetworkMode = EHazeCapabilityNetworkMode::Local;

	default DebugCategory = Drone::DebugCategory;

	default CapabilityTags.Add(CapabilityTags::GameplayAction);

	default CapabilityTags.Add(MagnetDroneTags::BlockedWhileAttraction);

	default TickGroup = EHazeTickGroup::ActionMovement;
	default TickGroupOrder = 70;	// Before the regular jump

	UMagnetDroneAttachedComponent AttachedComp;
	UPinballMagnetDroneComponent PinballComp;
	UHazeMovementComponent MoveComp;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		AttachedComp = UMagnetDroneAttachedComponent::Get(Player);
		PinballComp = UPinballMagnetDroneComponent::Get(Player);
		MoveComp = UHazeMovementComponent::Get(Player);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if(!HasControl())
			return false;

		if(MoveComp.HasMovedThisFrame())
			return false;

		if(!AttachedComp.IsAttached())
			return false;

		if(!WasActionStartedDuringTime(ActionNames::MovementJump, PinballComp.MovementSettings.JumpInputBufferTime))
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
		// We don't actually jump when magnetically attached in Pinball, we just play some vfx
		Player.ConsumeButtonInputsRelatedTo(ActionNames::MovementJump);

		UMagnetDroneEventHandler::Trigger_NoMagneticSurfaceFound(Player);
	}
}