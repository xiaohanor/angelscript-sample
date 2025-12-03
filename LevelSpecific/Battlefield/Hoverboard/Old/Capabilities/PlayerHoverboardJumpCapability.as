class UPlayerHoverboardJumpCapability : UHazePlayerCapability
{
	default CapabilityTags.Add(n"HoverboardJump");

	default TickGroup = EHazeTickGroup::Gameplay;

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

		if (!WasActionStarted(ActionNames::MovementJump))
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		return true;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		HoverboardUserComponent.Hoverboard.ActorVelocity += HoverboardUserComponent.Hoverboard.MovementWorldUp * 3500.0;

		// Player.PlayOverrideAnimation(FHazeAnimationDelegate(), HoverboardUserComponent.JumpAnimation, Priority = EHazeAnimPriority::AnimPrio_MAX);
		// Player.PlaySlotAnimation(Animation = HoverboardUserComponent.JumpAnimation);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		
	}
}