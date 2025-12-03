class UPlayerHoverboardEnterCapability : UHazePlayerCapability
{
	UHoverboardUserComponent HoverboardUserComponent;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		HoverboardUserComponent = UHoverboardUserComponent::Get(Player);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (!WasActionStarted(ActionNames::Interaction))
			return false;

		if (HoverboardUserComponent.Hoverboard == nullptr)
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		// if (!WasActionStarted(ActionNames::Interaction))
		// 	return false;

		// if (ActiveDuration < 0.1)
			return false;

		// return true;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		Player.BlockCapabilities(CapabilityTags::Movement, this);
		HoverboardUserComponent.Hoverboard.DetachFromActor();
		Player.AttachToComponent(HoverboardUserComponent.Hoverboard.PlayerAttach);
		HoverboardUserComponent.Hoverboard.ActorVelocity = Player.ActorVelocity;
		HoverboardUserComponent.Hoverboard.bActive = true;
		HoverboardUserComponent.Hoverboard.SetActorHiddenInGame(false);
		Player.ActivateCamera(HoverboardUserComponent.Hoverboard.Camera, 1.0, this);

/*
		FHazePointOfInterest POI;
		POI.FocusTarget.Component = HoverboardUserComponent.Hoverboard.CameraFocusTarget;
		POI.Blend.BlendTime = 1.0;

		Player.ApplyPointOfInterest(POI, this);
*/
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		Player.UnblockCapabilities(CapabilityTags::Movement, this);
		Player.DetachFromActor();
		HoverboardUserComponent.Hoverboard.bActive = false;
		HoverboardUserComponent.Hoverboard.AttachToActor(Player, n"Backpack");
		Player.DeactivateCameraByInstigator(this);
	
//		Player.ClearPointOfInterestByInstigator(this);
	}
}