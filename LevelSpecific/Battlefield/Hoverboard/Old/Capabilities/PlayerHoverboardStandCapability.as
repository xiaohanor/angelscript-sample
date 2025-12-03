class UPlayerHoverboardStandCapability : UHazePlayerCapability
{
	default CapabilityTags.Add(n"HoverboardStand");

	default TickGroup = EHazeTickGroup::Input;

	UHoverboardUserComponent HoverboardUserComponent;

	UCameraPointOfInterest POI;

	FHazeAcceleratedVector AccelLoc;

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
	void OnActivated()
	{
		// Player.PlaySlotAnimation(Animation = HoverboardUserComponent.StandAnimation, bLoop =  true);
		POI = Player.CreatePointOfInterest();
		POI.Apply(this, 0.8);
		AccelLoc.SnapTo(GetFocusTargetLocation());
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		// Player.StopSlotAnimationByAsset(HoverboardUserComponent.StandAnimation);
		Player.ClearPointOfInterestByInstigator(this);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		AccelLoc.AccelerateTo(GetFocusTargetLocation(), 1.5, DeltaTime);
		POI.FocusTarget.SetFocusToWorldLocation(AccelLoc.Value);

		// VERY TEMP WILL FIX WHEN I REWRITE THIS, SORRY
		if(WasActionStarted(ActionNames::MovementJump))
			Player.RequestLocomotion(n"HoverboardJumping", this);
		else if(HoverboardUserComponent.Hoverboard.MovementComponent.IsInAir())
			Player.RequestLocomotion(n"HoverboardAirMovement", this);
		else if(HoverboardUserComponent.Hoverboard.MovementComponent.WasInAir()
		&& HoverboardUserComponent.Hoverboard.MovementComponent.IsOnWalkableGround())
			Player.RequestLocomotion(n"HoverboardLanding", this);
		else
			Player.RequestLocomotion(n"Hoverboard", this);
		// Debug::DrawDebugSphere(AccelLoc.Value, 800.0, LineColor = FLinearColor::Red, Thickness = 50.0);
	}

	FVector GetFocusTargetLocation()
	{
		FVector Velocity = HoverboardUserComponent.Hoverboard.MovementComponent.Velocity.GetSafeNormal();
		Velocity.Z = Math::Clamp(Velocity.Z, -0.4, 0.0);
		Velocity.Normalize();
		return HoverboardUserComponent.Hoverboard.Pivot.WorldLocation + Velocity * 4000.0;
	}
}