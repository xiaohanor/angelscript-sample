class UPlayerHoverboardGrabCapability : UHazePlayerCapability
{
	default CapabilityTags.Add(n"HoverboardGrab");

	default TickGroup = EHazeTickGroup::Input;

	UHoverboardUserComponent HoverboardUserComponent;

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

		if (!IsActioning(ActionNames::Cancel))
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

		if (!IsActioning(ActionNames::Cancel))
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		Player.BlockCapabilities(n"HoverboardStand", this);
		Player.BlockCapabilities(n"HoverboardJump", this);

		PrintToScreen("Grab!", 1.0, FLinearColor::Green);
//		Player.PlayOverrideAnimation(FHazeAnimationDelegate(), HoverboardUserComponent.GrabAnimation, bLoop = true, Priority = EHazeAnimPriority::AnimPrio_MAX);
		Player.PlaySlotAnimation(Animation = HoverboardUserComponent.GrabAnimation, bLoop =  true);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		Player.UnblockCapabilities(n"HoverboardStand", this);
		Player.UnblockCapabilities(n"HoverboardJump", this);

		PrintToScreen("Stop Grab!", 1.0, FLinearColor::Green);
//		Player.StopOverrideAnimation(HoverboardUserComponent.GrabAnimation);
		Player.StopSlotAnimationByAsset(HoverboardUserComponent.GrabAnimation);
	}
}