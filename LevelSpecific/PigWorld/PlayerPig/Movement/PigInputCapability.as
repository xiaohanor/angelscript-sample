class UPigInputCapability : UHazePlayerCapability
{
	default CapabilityTags.Add(CapabilityTags::Movement);
	default CapabilityTags.Add(CapabilityTags::StickInput);
	default CapabilityTags.Add(CapabilityTags::MovementInput);

	default BlockExclusionTags.Add(CapabilityTags::MovementInput);

	default TickGroup = EHazeTickGroup::BeforeMovement;
	default TickGroupOrder = MovementInput::CapabilityTickGroupOrder;

	default DebugCategory = PigTags::Pig;

	UPlayerMovementComponent MovementComponent;

	FStickSnapbackDetector SnapbackDetector;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		MovementComponent = UPlayerMovementComponent::Get(Owner);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		Player.ClearMovementInput(this);
	}

	// Thieved from UPlayerMovementSquareDirectionInputCapability
	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		FVector Forward;
		FVector Right;
		FVector Up;
		if(MovementComponent.InputPlaneLock.IsDefaultValue())
		{
			const FRotator ControlRotation = Player.GetControlRotation();
			Up = MovementComponent.WorldUp;
			Forward = MovementInput::FixupMovementForwardVector(ControlRotation, Up);	
			Right = MovementInput::FixupMovementRightVector(ControlRotation, Up, Forward);
		}
		else
		{
			FInputPlaneLock InputPlane = MovementComponent.InputPlaneLock.Get();
			Up = Player.MovementWorldUp;
			Forward = InputPlane.UpDown;
			Right = InputPlane.LeftRight;
		}	

		const FVector2D RawStick = GetAttributeVector2D(AttributeVectorNames::MovementRaw);
		FVector CurrentInput = Forward * RawStick.X + Right * RawStick.Y;

		const FVector StickInput(RawStick.X, RawStick.Y, 0);
		FVector MoveDirWithoutSnap = SnapbackDetector.RemoveStickSnapbackJitter(StickInput, CurrentInput);
		Player.ApplyMovementInput(MoveDirWithoutSnap, this);
	}
}