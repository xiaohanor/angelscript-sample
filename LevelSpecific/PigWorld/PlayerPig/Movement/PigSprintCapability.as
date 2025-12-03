class UPigSprintCapability : UHazePlayerCapability
{
	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;

	default CapabilityTags.Add(CapabilityTags::Movement);
	default CapabilityTags.Add(CapabilityTags::GameplayAction);	
	default CapabilityTags.Add(PlayerMovementTags::CoreMovement);
	default CapabilityTags.Add(PlayerMovementTags::Sprint);

	default TickGroup = EHazeTickGroup::BeforeMovement;
	default TickGroupOrder = 90;

	default DebugCategory = PigTags::Pig;

	UPlayerPigComponent PigComponent;
	UPlayerMovementComponent MovementComponent;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		PigComponent = UPlayerPigComponent::Get(Owner);
		MovementComponent = UPlayerMovementComponent::Get(Owner);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (!WasActionStarted(ActionNames::MovementSprint))
			return false;

		if(MovementComponent.MovementInput.IsNearlyZero())
			return false;

		if (!MovementComponent.IsOnWalkableGround())
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if(MovementComponent.MovementInput.Size() < 0.7)
			return true;

		if(MovementComponent.Velocity.IsNearlyZero())
			return true;

		if (!MovementComponent.IsOnWalkableGround())
			return true;

		if(MovementComponent.HasWallContact())
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		UPigMovementSettings::SetSpeedMultiplier(Player, 1.5, this);

		if (!SceneView::IsFullScreen())
		{
			UCameraSettings::GetSettings(Player).FOV.ApplyAsAdditive(5, this, 1);
			SpeedEffect::RequestSpeedEffect(Player, 0.2, this, EInstigatePriority::Normal);
		}
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		UPigMovementSettings::ClearSpeedMultiplier(Player, this);

		UCameraSettings::GetSettings(Player).FOV.Clear(this, 2.0);
		SpeedEffect::ClearSpeedEffect(Player, this);
	}
}