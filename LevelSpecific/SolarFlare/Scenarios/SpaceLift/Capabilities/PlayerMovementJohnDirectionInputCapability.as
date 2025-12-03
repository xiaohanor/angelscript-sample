class UPlayerMovementJohnDirectionInputCapability : UHazePlayerCapability
{
	default CapabilityTags.Add(CapabilityTags::Movement);
	default CapabilityTags.Add(CapabilityTags::StickInput);
	default CapabilityTags.Add(CapabilityTags::MovementInput);

	default BlockExclusionTags.Add(CapabilityTags::MovementInput);

	default DebugCategory = n"Movement";
	
	default TickGroup = EHazeTickGroup::BeforeMovement;
	default TickGroupOrder = MovementInput::CapabilityTickGroupOrder;

	UPlayerMovementComponent MoveComponent;
	FStickSnapbackDetector SnapbackDetector;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		MoveComponent = UPlayerMovementComponent::Get(Player);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if(MoveComponent.WantedMovementInputCapabilityType != EPlayerMovementInputCapabilityType::Oval)
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if(MoveComponent.WantedMovementInputCapabilityType == EPlayerMovementInputCapabilityType::Oval)
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		Player.ClearMovementInput(this);
		SnapbackDetector.ClearSnapbackDetection();
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		FVector Forward;
		FVector Right;
		FVector Up;
		if(MoveComponent.InputPlaneLock.IsDefaultValue())
		{
			const FRotator ControlRotation = Player.GetControlRotation();
			Up = MoveComponent.GetWorldUp();
			Forward = MovementInput::FixupMovementForwardVector(ControlRotation, Up);	
			Right = MovementInput::FixupMovementRightVector(ControlRotation, Up, Forward);
		}
		else
		{
			FInputPlaneLock InputPlane = MoveComponent.InputPlaneLock.Get();
			Up = Player.MovementWorldUp;
			Forward = InputPlane.UpDown;
			Right = InputPlane.LeftRight;
		}	
	
		FVector2D RawStick = GetAttributeVector2D(AttributeVectorNames::MovementRaw);
		RawStick.X = 0.0;

		// This math will make the x and y axis more oval, making it easier to make small adjustments,
		// but it will also making the diagonal directions be a bit skewed.
		FVector CurrentInput = 
			(Forward * Math::Pow(RawStick.X, 2.0) * Math::Sign(RawStick.X)) + 
			(Right * Math::Pow(RawStick.Y, 2.0) * Math::Sign(RawStick.Y));
		CurrentInput = CurrentInput.GetSafeNormal() * RawStick.Size();
		
		const FVector StickInput(RawStick.X, RawStick.Y, 0);
		FVector MoveDirWithoutSnap = SnapbackDetector.RemoveStickSnapbackJitter(StickInput, CurrentInput);
		Player.ApplyMovementInput(MoveDirWithoutSnap, this, EInstigatePriority::Normal);
	
		// DEBUG
		{
			MovementInputDebug::FDebugData DebugData(MoveComponent);
			DebugData.XAxisDirection = Forward;
			DebugData.YAxisDirection = Right;
			MovementInputDebug::WriteToTemporalLog(Player, this, DebugData);
		}	
	}
};