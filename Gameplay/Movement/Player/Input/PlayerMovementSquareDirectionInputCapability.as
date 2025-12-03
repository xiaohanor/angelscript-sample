


class UPlayerMovementSquareDirectionInputCapability : UHazePlayerCapability
{
	default CapabilityTags.Add(CapabilityTags::Movement);
	default CapabilityTags.Add(CapabilityTags::StickInput);
	default CapabilityTags.Add(CapabilityTags::MovementInput);

	default BlockExclusionTags.Add(CapabilityTags::MovementInput);

	default DebugCategory = n"Movement";
	
	default TickGroup = EHazeTickGroup::BeforeMovement;
	default TickGroupOrder = MovementInput::CapabilityTickGroupOrder;

	UPlayerMovementComponent MoveComponent;
	UPlayerTargetablesComponent TargetablesComponent;
	FStickSnapbackDetector SnapbackDetector;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		MoveComponent = UPlayerMovementComponent::Get(Player);
		TargetablesComponent = UPlayerTargetablesComponent::GetOrCreate(Player);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if(MoveComponent.WantedMovementInputCapabilityType != EPlayerMovementInputCapabilityType::Square)
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if(MoveComponent.WantedMovementInputCapabilityType == EPlayerMovementInputCapabilityType::Square)
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
		TargetablesComponent.PlayerTargetingInput = FVector::ZeroVector;
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		FVector Forward;
		FVector Right;
		if(MoveComponent.InputPlaneLock.IsDefaultValue())
		{
			const FVector Up = MoveComponent.GetWorldUp();
			const FRotator ControlRotation = Player.GetControlRotation();
			Forward = MovementInput::FixupMovementForwardVector(ControlRotation, Up);	
			Right = MovementInput::FixupMovementRightVector(ControlRotation, Up, Forward);
		}
		else
		{
			FInputPlaneLock InputPlane = MoveComponent.InputPlaneLock.Get();
			Forward = InputPlane.UpDown;
			Right = InputPlane.LeftRight;
		}	

		const FVector2D RawStick = GetAttributeVector2D(AttributeVectorNames::MovementRaw);
		FVector CurrentInput = Forward * RawStick.X + Right * RawStick.Y;
			
		const FVector StickInput(RawStick.X, RawStick.Y, 0);
		FVector MoveDirWithoutSnap = SnapbackDetector.RemoveStickSnapbackJitter(StickInput, CurrentInput);
		Player.ApplyMovementInput(MoveDirWithoutSnap, this);	

		if (TargetablesComponent.TargetingMode.Get() == EPlayerTargetingMode::SideScroller)
		{
			FVector TargetingInput = 
				(MoveComponent.WorldUp * Math::Pow(RawStick.X, 2.0) * Math::Sign(RawStick.X)) + 
				(Right * Math::Pow(RawStick.Y, 2.0) * Math::Sign(RawStick.Y));
			TargetingInput = TargetingInput.GetSafeNormal() * RawStick.Size();
			TargetablesComponent.PlayerTargetingInput = TargetingInput;
		}
		else
		{
			TargetablesComponent.PlayerTargetingInput = MoveDirWithoutSnap;
		}

		// DEBUG
		{
			MovementInputDebug::FDebugData DebugData(MoveComponent);
			DebugData.XAxisDirection = Forward;
			DebugData.YAxisDirection = Right;
			MovementInputDebug::WriteToTemporalLog(Player, this, DebugData);
		}	
	}
};