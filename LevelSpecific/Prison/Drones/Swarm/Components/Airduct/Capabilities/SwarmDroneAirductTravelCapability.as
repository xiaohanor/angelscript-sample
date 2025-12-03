class USwarmDroneAirductTravelCapability : UHazePlayerCapability
{
	default CapabilityTags.Add(PrisonTags::Prison);
	default CapabilityTags.Add(PrisonTags::Drones);
	default CapabilityTags.Add(SwarmDroneTags::SwarmDrone);

	default CapabilityTags.Add(SwarmDroneTags::SwarmAirductCapability);
	default CapabilityTags.Add(SwarmDroneTags::SwarmAirductTravelCapability);

	default TickGroup = EHazeTickGroup::Movement;

	UPlayerSwarmDroneComponent SwarmDroneComponent;
	UPlayerSwarmDroneAirductComponent PlayerAirductComponent;

	USwarmDroneAirductComponent CurrentAirductComponent = nullptr;

	FVector InitialLocation;

	UFUNCTION(BlueprintOverride)
	void Setup()
{
		SwarmDroneComponent = UPlayerSwarmDroneComponent::Get(Owner);
		PlayerAirductComponent = UPlayerSwarmDroneAirductComponent::Get(Owner);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (!PlayerAirductComponent.InAirduct())
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (ActiveDuration > CurrentAirductComponent.TravelDuration)
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		CurrentAirductComponent = PlayerAirductComponent.CurrentAirductComponent;
		InitialLocation = Player.ActorLocation;

		PlayerAirductComponent.OnSwarmDroneAirductSuckedEvent.Broadcast(CurrentAirductComponent);

		//Player.ApplyCameraSettings(CurrentAirductComponent.TravelCameraSettings, 1.0, this, SubPriority = 65);

		// Teleport player without camera snap
		Player.TeleportActor(Player.ActorLocation, CurrentAirductComponent.GetWorldExhaustTransform().Rotator(), this, false);
		Player.BlockCapabilities(CapabilityTags::Movement, this);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		PlayerAirductComponent.bWasJustExpelled = true;

		Player.ClearCameraSettingsByInstigator(this, 2.0);

		Player.UnblockCapabilities(CapabilityTags::Movement, this);

		PlayerAirductComponent.bInAirduct = false;
		CurrentAirductComponent = nullptr;

		InitialLocation = FVector::ZeroVector;
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		const float TravelFraction = Math::Saturate(ActiveDuration / CurrentAirductComponent.TravelDuration);

		// Move camera
		//FVector NextLocation = GetNextLocation(TravelFraction);

		//UCameraSettings::GetSettings(Player).WorldPivotOffset.Apply(NextLocation - Player.ActorLocation, this, Priority = EHazeCameraPriority::High);
	}

	// FVector GetNextLocation(const float TravelFraction)
	// {
	// 	FVector NextLocation = FVector::ZeroVector;

	// 	if (CurrentAirductComponent.TravelSpline != nullptr)
	// 	{
	// 		// Get location from spline
	// 		float SplineDistance = TravelFraction * CurrentAirductComponent.TravelSpline.GetSplineLength();
	// 		NextLocation = CurrentAirductComponent.TravelSpline.GetWorldLocationAtSplineDistance(SplineDistance);
	// 	}
	// 	else
	// 	{
	// 		NextLocation = Math::Lerp(InitialLocation, CurrentAirductComponent.GetWorldExhaustTransform().Location, TravelFraction);
	// 	}

	// 	return NextLocation;
	// }
}