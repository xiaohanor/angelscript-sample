class UTundra_SimonSaysPlayerInputCapability : UHazePlayerCapability
{
	default CapabilityTags.Add(CapabilityTags::GameplayAction);
	default CapabilityTags.Add(CapabilityTags::Input);
	default CapabilityTags.Add(CapabilityTags::MovementInput);

	default TickGroup = EHazeTickGroup::BeforeMovement;
	default TickGroupOrder = MovementInput::CapabilityTickGroupOrder;

	UPlayerMovementComponent MoveComp;
	UTundra_SimonSaysPlayerComponent PlayerComp;
	UPlayerTargetablesComponent TargetablesComp;
	FStickSnapbackDetector SnapbackDetector;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		PlayerComp = UTundra_SimonSaysPlayerComponent::GetOrCreate(Player);
		MoveComp = UPlayerMovementComponent::Get(Player);
		TargetablesComp = UPlayerTargetablesComponent::Get(Player);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if(PlayerComp.CurrentPerchedTile == nullptr)
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if(PlayerComp.CurrentPerchedTile == nullptr)
			return true;
		
		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		Player.BlockCapabilities(CapabilityTags::MovementInput, this);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		MoveComp.ClearMovementInput(this);
		SnapbackDetector.ClearSnapbackDetection();
		Player.UnblockCapabilities(CapabilityTags::MovementInput, this);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		FVector Forward;
		FVector Right;
		FVector Up;
		if(MoveComp.InputPlaneLock.IsDefaultValue())
		{
			const FRotator ControlRotation = Player.GetControlRotation();
			Up = MoveComp.GetWorldUp();
			Forward = MovementInput::FixupMovementForwardVector(ControlRotation, Up);	
			Right = MovementInput::FixupMovementRightVector(ControlRotation, Up, Forward);
		}
		else
		{
			FInputPlaneLock InputPlane = MoveComp.InputPlaneLock.Get();
			Up = Player.MovementWorldUp;
			Forward = InputPlane.UpDown;
			Right = InputPlane.LeftRight;
		}	
	
		FVector2D RawStick;
		if(Player.IsUsingGamepad())
		{
			RawStick = GetAttributeVector2D(n"GamepadLeftStick_NoDeadZone");
			RawStick = FVector2D(RawStick.Y, RawStick.X);
		}
		else
		{
			RawStick = GetAttributeVector2D(AttributeVectorNames::MovementRaw);
		}

		// Add middle deadzone since we might grab the NoDeadZone (we grab the NoDeadZone because we want to remove the dead zone that snaps the input to the cardinal directions, but we still want a center deadzone)
		if(RawStick.IsNearlyZero(0.5))
			RawStick = FVector2D::ZeroVector;

		// This math will make the x and y axis more oval, making it easier to make small adjustments,
		// but it will also making the diagonal directions be a bit skewed.
		FVector CurrentInput = 
			(Forward * RawStick.X) + 
			(Right * RawStick.Y);
		CurrentInput = CurrentInput.GetSafeNormal() * RawStick.Size();
		
		const FVector StickInput(RawStick.X, RawStick.Y, 0);
		FVector MoveDirWithoutSnap = SnapbackDetector.RemoveStickSnapbackJitter(StickInput, CurrentInput);
		Player.ApplyMovementInput(MoveDirWithoutSnap, this);
		TargetablesComp.PlayerTargetingInput = MoveDirWithoutSnap;

		// DEBUG
		{
			MovementInputDebug::FDebugData DebugData(MoveComp);
			DebugData.XAxisDirection = Forward;
			DebugData.YAxisDirection = Right;
			MovementInputDebug::WriteToTemporalLog(Player, this, DebugData);
		}	
	}
}