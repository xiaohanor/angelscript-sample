class UTeenDragonMovementInputCapability : UHazePlayerCapability
{
	default CapabilityTags.Add(CapabilityTags::StickInput);
	default CapabilityTags.Add(CapabilityTags::MovementInput);
	default CapabilityTags.Add(CapabilityTags::Input);

	default BlockExclusionTags.Add(CapabilityTags::MovementInput);

	default DebugCategory = SummitDebugCapabilityTags::TeenDragon;
	
	default TickGroup = EHazeTickGroup::Input;
	default TickGroupOrder = MovementInput::CapabilityTickGroupOrder;

	UHazeMovementComponent MoveComponent;
	UPlayerTeenDragonComponent DragonComp;
	FStickSnapbackDetector SnapbackDetector;

	bool bHadInputPreviousFrame;
	FVector PreviousForward;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		MoveComponent = UHazeMovementComponent::Get(Player);
		DragonComp = UPlayerTeenDragonComponent::Get(Player);
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
		if(!HasControl())
			return;

		const FVector Up = MoveComponent.GetWorldUp();
		const FRotator ControlRotation = Player.GetControlRotation();
		FVector2D RawStick = GetAttributeVector2D(AttributeVectorNames::MovementRaw);

		FVector CurrentInput;

		if (DragonComp.VerticalInputInstigators.Num() > 0)
		{
			CurrentInput = GetVerticalInput(RawStick, Up);
		}
		else if(DragonComp.NonOrientedInputInstigators.Num() > 0)
		{
			FVector Forward = FVector::ForwardVector;
			FVector Right = FVector::RightVector;
			CurrentInput = Forward * RawStick.X + Right * RawStick.Y; 
		}
		else
		{
			FVector Forward = ControlRotation.ForwardVector.ConstrainToPlane(Up).GetSafeNormal();
			if (Forward.IsZero())
				Forward = ControlRotation.UpVector.ConstrainToPlane(Up).GetSafeNormal();
				
			const FVector Right = Up.CrossProduct(Forward) * Math::Sign(ControlRotation.UpVector.DotProduct(Up));
			
			// Smooth out the input so we can make small turn adjustments
			CurrentInput = 
				(Forward * Math::Pow(RawStick.X, 2.0) * Math::Sign(RawStick.X)) + 
				(Right * Math::Pow(RawStick.Y, 2.0) * Math::Sign(RawStick.Y));
			CurrentInput = CurrentInput.GetSafeNormal() * RawStick.Size();
		}

		const FVector StickInput(RawStick.X, RawStick.Y, 0);
		FVector MoveDirWithoutSnap = SnapbackDetector.RemoveStickSnapbackJitter(StickInput, CurrentInput);

		Owner.ApplyMovementInput(MoveDirWithoutSnap, this);

		if (!MoveDirWithoutSnap.IsNearlyZero() && DragonComp.VerticalInputInstigators.Num() == 0)
		{
			Owner.SetMovementFacingDirection(MoveDirWithoutSnap.GetSafeNormal());
		}
		else
		{
			Owner.SetMovementFacingDirection(Owner.ActorForwardVector);
		}
	}

	FVector GetVerticalInput(FVector2D RawStick, FVector Up)
	{
		FVector Horizontal = Up.CrossProduct(FVector::UpVector).GetSafeNormal();
			
		FVector Vertical = -Up.CrossProduct(Horizontal);
		FVector CurrentInput = Vertical * RawStick.X + Horizontal * RawStick.Y;

		return CurrentInput;
	}
};