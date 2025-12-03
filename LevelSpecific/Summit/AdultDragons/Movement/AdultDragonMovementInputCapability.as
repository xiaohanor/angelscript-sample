class UAdultDragonMovementInputCapability : UHazePlayerCapability
{
	default CapabilityTags.Add(CapabilityTags::Movement);
	default CapabilityTags.Add(CapabilityTags::StickInput);
	default CapabilityTags.Add(CapabilityTags::MovementInput);
	default CapabilityTags.Add(n"AdultDragonMovementInputCapability");

	default BlockExclusionTags.Add(CapabilityTags::MovementInput);

	default DebugCategory = n"AdultDragon";
	
	default TickGroup = EHazeTickGroup::BeforeMovement;
	default TickGroupOrder = MovementInput::CapabilityTickGroupOrder;

	// UAdultDragonMovementComponent MoveComponent;
	UPlayerMovementComponent MoveComponent;
	UPlayerAdultDragonComponent DragonComp;
	FStickSnapbackDetector SnapbackDetector;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		MoveComponent = UPlayerMovementComponent::Get(Player);

		DragonComp = UPlayerAdultDragonComponent::Get(Player);
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
	void OnActivated()
	{

	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		Owner.ClearMovementInput(this);
		SnapbackDetector.ClearSnapbackDetection();
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		const FVector Up = MoveComponent.GetWorldUp();
		FVector2D RawStick = GetAttributeVector2D(AttributeVectorNames::MovementRaw);

		// DragonComp.DragonTilt = RawStick.Y;

		FRotator ControlRotation = Player.GetControlRotation();

		// If we're looking slightly downward, ignore that, we are expecting it to be the neutral
		if (ControlRotation.Pitch < 0.0 && ControlRotation.Pitch > AdultDragonMovement::IgnoreLookingDownAngle)
			ControlRotation.Pitch = 0.0;

		FVector CurrentInput;

		FVector Forward = ControlRotation.ForwardVector;
		const FVector Right = Up.CrossProduct(Forward) * Math::Sign(ControlRotation.UpVector.DotProduct(Up));

		CurrentInput = Forward * RawStick.X + Right * RawStick.Y;

		const FVector StickInput(RawStick.X, RawStick.Y, 0);
		FVector MoveDirWithoutSnap = SnapbackDetector.RemoveStickSnapbackJitter(StickInput, CurrentInput);
		
		Owner.ApplyMovementInput(MoveDirWithoutSnap, this);

		FVector FacingVector = MoveDirWithoutSnap.ConstrainToPlane(FVector::UpVector);
		if (!FacingVector.IsNearlyZero())
		{
			Owner.SetMovementFacingDirection(FacingVector.GetSafeNormal());
		}
	}
};