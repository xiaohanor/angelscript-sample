class USpaceWalkThrustCapability : UHazePlayerCapability
{
	default TickGroup = EHazeTickGroup::BeforeMovement;

	const float TotalThrust = 2000.0;
	const float ThrustDuration = 0.25;
	const float CooldownDuration = 1.0;
	UPlayerMovementComponent MoveComp;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		MoveComp = UPlayerMovementComponent::Get(Player);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (!WasActionStarted(ActionNames::MovementDash))
			return false;
		if (DeactiveDuration < CooldownDuration)
			return false;
		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (ActiveDuration > ThrustDuration)
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
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		FVector2D Input = GetAttributeVector2D(AttributeVectorNames::MovementRaw);
		float VerticalMovement = 0.0;
		if (IsActioning(ActionNames::MovementVerticalUp))
			VerticalMovement += 1.0;
		if (IsActioning(ActionNames::MovementVerticalDown))
			VerticalMovement -= 1.0;

		FVector WantedThrust;
		WantedThrust += Player.ViewRotation.ForwardVector * Input.X;
		WantedThrust += Player.ViewRotation.RightVector * Input.Y;
		WantedThrust += MoveComp.WorldUp * VerticalMovement;
		WantedThrust = WantedThrust.GetSafeNormal();

		if (WantedThrust.IsNearlyZero())
			WantedThrust = Player.ViewRotation.ForwardVector;

		Player.AddMovementImpulse(WantedThrust * DeltaTime * TotalThrust / ThrustDuration);
		Player.RequestLocomotion(n"AirDash", this);
	}
};