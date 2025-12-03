class UTundraPlayerFairySteeringInputCapability : UHazePlayerCapability
{
	default CapabilityTags.Add(TundraShapeshiftingTags::Fairy);
	default CapabilityTags.Add(CapabilityTags::Movement);
	default CapabilityTags.Add(CapabilityTags::StickInput);
	default CapabilityTags.Add(CapabilityTags::MovementInput);

	default BlockExclusionTags.Add(CapabilityTags::MovementInput);
	default BlockExclusionTags.Add(TundraShapeshiftingTags::Fairy);

	default DebugCategory = n"Movement";
	
	default TickGroup = EHazeTickGroup::BeforeMovement;
	default TickGroupOrder = MovementInput::CapabilityTickGroupOrder;

	UPlayerMovementComponent MoveComponent;
	FStickSnapbackDetector SnapbackDetector;
	UTundraPlayerFairyComponent FairyComp;
	UTundraPlayerFairySettings Settings;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		MoveComponent = UPlayerMovementComponent::Get(Player);
		FairyComp = UTundraPlayerFairyComponent::Get(Player);
		Settings = UTundraPlayerFairySettings::GetSettings(Player);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if(!FairyComp.bIsActive)
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if(!FairyComp.bIsActive)
			return true;

		return false;
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
		const FVector Up = MoveComponent.GetWorldUp();
		const FRotator ControlRotation = Player.GetControlRotation();

		const FVector Forward = MovementInput::FixupMovementForwardVector(ControlRotation, Up);	
		const FVector Right = MovementInput::FixupMovementRightVector(ControlRotation, Up, Forward);
	
		FVector2D RawStick = GetAttributeVector2D(AttributeVectorNames::MovementRaw);
		if(FairyComp.bIsLeaping && !MoveComponent.HasGroundContact() && !RawStick.IsNearlyZero())
		{
			float CurrentAngleDeg = Math::DirectionToAngleDegrees(RawStick);
			float NewAngleDeg = Math::Clamp(CurrentAngleDeg, -Settings.MaxLeapingInputAngle, Settings.MaxLeapingInputAngle);
			RawStick = Math::AngleDegreesToDirection(NewAngleDeg);
		}

		// This math will make the x and y axis more oval, making it easier to make small adjustments,
		// but it will also making the diagonal directions be a bit skewed.
		//FVector CurrentInput = 
		//	(Forward * Math::Pow(RawStick.X, 2.0) * Math::Sign(RawStick.X)) + 
		//	(Right * Math::Pow(RawStick.Y, 2.0) * Math::Sign(RawStick.Y));

		FVector CurrentInput = 
			(Forward * RawStick.X) + 
			(Right * RawStick.Y);
		CurrentInput = CurrentInput.GetSafeNormal() * RawStick.Size();
		
		const FVector StickInput(RawStick.X, RawStick.Y, 0);
		FVector MoveDirWithoutSnap = SnapbackDetector.RemoveStickSnapbackJitter(StickInput, CurrentInput);

		Player.ApplyMovementInput(MoveDirWithoutSnap, this);
	}
}