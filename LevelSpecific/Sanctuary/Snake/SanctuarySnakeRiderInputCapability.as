class USanctuarySnakeRiderInputCapability : UHazePlayerCapability
{
	default CapabilityTags.Add(n"SanctuarySnake");
	default CapabilityTags.Add(CapabilityTags::StickInput);
	default CapabilityTags.Add(CapabilityTags::MovementInput);

	default DebugCategory = n"Movement";
	
	default TickGroup = EHazeTickGroup::BeforeMovement;
	default TickGroupOrder = MovementInput::CapabilityTickGroupOrder;

	ASanctuarySnake Snake;
	UHazeMovementComponent SnakeMovementComponent;
	FVector LastInput;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{

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
		auto SnakeRiderComponent = USanctuarySnakeRiderComponent::Get(Player);
		Snake = SnakeRiderComponent.Snake;
		SnakeMovementComponent = UHazeMovementComponent::Get(Snake);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		Snake.ClearMovementInput(this);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		FVector MovementUp = SnakeMovementComponent.GetWorldUp();
		FRotator ControlRotation = Player.GetControlRotation();

		FVector Forward = ControlRotation.RightVector.CrossProduct(MovementUp);
		if (Forward.IsNearlyZero(0.1))
			Forward = ControlRotation.UpVector;
		else
			Forward.Normalize();

		FVector Right = MovementUp.CrossProduct(Forward).GetSafeNormal();

//		if (Player.CurrentlyUsedCamera != Snake.RiderCamera)
//			Up = -Player.CurrentlyUsedCamera.ForwardVector;

//		FVector Forward = ControlRotation.UpVector.ConstrainToPlane(Up).GetSafeNormal();

//		if (Forward.IsZero())
//			Forward = ControlRotation.ForwardVector.ConstrainToPlane(Up).GetSafeNormal();
			
//		FVector Right = ControlRotation.RightVector.ConstrainToPlane(Up).GetSafeNormal();
		if (Right.IsZero())
			Right = MovementUp.CrossProduct(Forward) * Math::Sign(ControlRotation.UpVector.DotProduct(MovementUp));

		FVector2D RawStick = GetAttributeVector2D(AttributeVectorNames::MovementRaw);

		// This math will make the x and y axis more oval, making it easier to make small adjustments,
		// but it will also making the diagonal directions be a bit skewed.
		FVector CurrentInput = 
			(Forward * Math::Pow(RawStick.X, 2.0) * Math::Sign(RawStick.X)) + 
			(Right * Math::Pow(RawStick.Y, 2.0) * Math::Sign(RawStick.Y));
		CurrentInput = CurrentInput.GetSafeNormal() * RawStick.Size();
		Snake.ApplyMovementInput(CurrentInput, this);

//		Debug::DrawDebugLine(Owner.ActorLocation, Owner.ActorLocation + MovementUp * 500.0, FLinearColor::LucBlue, 10.0, 0.0);
//		Debug::DrawDebugLine(Owner.ActorLocation, Owner.ActorLocation + Forward * 900.0, FLinearColor::Red, 60.0, 0.0);
//		Debug::DrawDebugLine(Owner.ActorLocation, Owner.ActorLocation + Right * 300.0, FLinearColor::Green, 100.0, 0.0);
//		Debug::DrawDebugLine(Owner.ActorLocation, Owner.ActorLocation + CurrentInput * 500.0, FLinearColor::Purple, 10.0, 0.0);
//		Debug::DrawDebugLine(Owner.ActorLocation, Owner.ActorLocation + ControlRotation.UpVector * 700.0, FLinearColor::Yellow, 20.0, 0.0);
//		Debug::DrawDebugLine(Owner.ActorLocation, Owner.ActorLocation + ControlRotation.RightVector * 700.0, FLinearColor::Gray, 20.0, 0.0);
	}
};