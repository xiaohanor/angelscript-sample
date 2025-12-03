class UPlayerHoverboardTurnCapability : UHazePlayerCapability
{
	default CapabilityTags.Add(n"HoverboardTurn");

	default TickGroup = EHazeTickGroup::Input;

	UHoverboardUserComponent HoverboardUserComponent;

	float LeanLerpSpeed = 10.0;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		HoverboardUserComponent = UHoverboardUserComponent::Get(Owner);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (HoverboardUserComponent.Hoverboard == nullptr)
			return false;

		if (!HoverboardUserComponent.Hoverboard.bActive)
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (HoverboardUserComponent.Hoverboard == nullptr)
			return true;

		if (!HoverboardUserComponent.Hoverboard.bActive)
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		FVector2D Input = GetAttributeVector2D(AttributeVectorNames::LeftStickRaw);

		if (IsActioning(ActionNames::Cancel))
			Input *= 2.0;

		HoverboardUserComponent.Input = Input;

		// Move to seperate input capability, put it here so anim can work
		FVector MovementInput = FVector(Input.X, Input.Y, 0);
		Player.ApplyMovementInput(MovementInput, this, EInstigatePriority::Normal);
	//	PrintToScreen("" + Owner.Name + " is giving input to SlidingDisc" + Input, 0.0, FLinearColor::Green);

		HoverboardUserComponent.Lean = Math::Lerp(HoverboardUserComponent.Lean, HoverboardUserComponent.Input, LeanLerpSpeed * DeltaTime);

		HoverboardUserComponent.Hoverboard.Lean = HoverboardUserComponent.Lean;

	//	Player.RequestLocomotion(n"Hoverboard", this);
		PrintToScreen("Lean: " + HoverboardUserComponent.Hoverboard.Lean, 0.0, FLinearColor::Green);
	}
}