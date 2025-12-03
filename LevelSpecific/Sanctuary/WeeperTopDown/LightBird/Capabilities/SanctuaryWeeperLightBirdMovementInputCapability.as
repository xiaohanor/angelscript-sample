class USanctuaryWeeperLightBirdMovementInputCapability : UHazeCapability
{
	default CapabilityTags.Add(CapabilityTags::Input);
	default CapabilityTags.Add(CapabilityTags::StickInput);
	default CapabilityTags.Add(CapabilityTags::MovementInput);

	default TickGroup = EHazeTickGroup::Input;
	default TickGroupOrder = 150;

	UHazeMovementComponent MoveComp;
	ASanctuaryWeeperLightBird LightBird;
	USanctuaryWeeperLightBirdUserComponent UserComp;
	AHazePlayerCharacter Player;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		LightBird = Cast<ASanctuaryWeeperLightBird>(Owner);
		Player = LightBird.Player;
		UserComp = USanctuaryWeeperLightBirdUserComponent::Get(Player);
		MoveComp = UHazeMovementComponent::Get(Owner);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (Player.IsPlayerDead())
			return false;

		if (!UserComp.IsTransformed())
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (Player.IsPlayerDead())
			return true;

		if (!UserComp.IsTransformed())
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		Owner.ClearMovementInput(this);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		FRotator ControlRotation = Player.ControlRotation;
		ControlRotation.Pitch = 0.0;

		FVector WorldUp = Player.MovementWorldUp;
		FVector ForwardVector = ControlRotation.ForwardVector;
		FVector UpVector = ControlRotation.UpVector;
		FVector RightVector = UpVector.CrossProduct(ForwardVector) * Math::Sign(UpVector.DotProduct(WorldUp));

		FVector2D RawStick = GetAttributeVector2D(AttributeVectorNames::MovementRaw);
		FVector InputDirection = ForwardVector * RawStick.X + RightVector * RawStick.Y;

		Owner.ApplyMovementInput(InputDirection, this);

		FVector FacingVector = InputDirection.ConstrainToPlane(FVector::UpVector);
		if (!FacingVector.IsNearlyZero())
		{
			Owner.SetMovementFacingDirection(FacingVector.GetSafeNormal());
		}

	}
}