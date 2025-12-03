
/**
 * This sends the player input to the drone
 */

 class UPinballMagnetDroneInputCapability : UHazePlayerCapability
 {
	default NetworkMode = EHazeCapabilityNetworkMode::Local;
	default DebugCategory = Drone::DebugCategory;

	default CapabilityTags.Add(CapabilityTags::StickInput);
	default CapabilityTags.Add(CapabilityTags::MovementInput);

	default TickGroup = EHazeTickGroup::Input;
	default TickGroupOrder = MovementInput::CapabilityTickGroupOrder + 1;

	UHazeMovementComponent MoveComp;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		MoveComp = UHazeMovementComponent::Get(Owner);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if(!HasControl())
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if(!HasControl())
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		Player.ClearMovementInput(this);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(const float Dt)
	{
		UpdateStickInput(Dt);
	}

	void UpdateStickInput(const float Dt)
	{
		const FVector2D MovementRaw = GetAttributeVector2D(AttributeVectorNames::MovementRaw);
		FVector MoveInput = FVector(0, MovementRaw.Y, MovementRaw.X);
		Player.ApplyMovementInput(MoveInput, this);
	}
 }