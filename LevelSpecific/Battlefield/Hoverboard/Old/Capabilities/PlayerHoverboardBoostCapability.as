class UPlayerHoverboardBoostCapability : UHazePlayerCapability
{
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

		if (!IsActioning(ActionNames::MovementDash))
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

		if (!IsActioning(ActionNames::MovementDash))
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
//		HoverboardUserComponent.Hoverboard.ActorVelocity += HoverboardUserComponent.Hoverboard.Pivot.ForwardVector * 800.0;
		HoverboardUserComponent.Hoverboard.bBoost = true;
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		if (HoverboardUserComponent.Hoverboard == nullptr)
			return;
		
		HoverboardUserComponent.Hoverboard.bBoost = false;	
	}
}