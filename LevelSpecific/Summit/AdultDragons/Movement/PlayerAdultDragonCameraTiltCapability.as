class UPlayerAdultDragonCameraTiltCapability : UHazePlayerCapability
{
	default CapabilityTags.Add(AdultDragonCapabilityTags::AdultDragon);
	default CapabilityTags.Add(AdultDragonCapabilityTags::AdultDragonCamera);
	default CapabilityTags.Add(CameraTags::Camera);
	default CapabilityTags.Add(CapabilityTags::BlockedWhileDead);
	//default CapabilityTags.Add(n"BlockedWhileDead");

	default TickGroup = EHazeTickGroup::BeforeMovement;
	default TickGroupOrder = 2; // after AdultDragonSplineFollowCameraCapability

	default DebugCategory = n"AdultDragon";

	UPlayerAdultDragonComponent DragonComp;
	UAdultDragonAirBreakComponent AirBreakComp;
	UPlayerMovementComponent MoveComp;

	UCameraUserComponent CameraUser;

	FHazeAcceleratedFloat AccCurrentYawAxisTilt;

	UAdultDragonFlightSettings FlightSettings;

	bool bShouldExit = false;

	float CurrentPitch;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		CameraUser = UCameraUserComponent::Get(Player);
		DragonComp = UPlayerAdultDragonComponent::Get(Player);
		MoveComp = UPlayerMovementComponent::Get(Player);
		AirBreakComp = UAdultDragonAirBreakComponent::Get(Player);
		FlightSettings = UAdultDragonFlightSettings::GetSettings(Player);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (AirBreakComp != nullptr)
		{
			if (AirBreakComp.bIsBreaking)
				return false;
		}

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (bShouldExit
			&& AccCurrentYawAxisTilt.Value == 0)
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		Player.BlockCapabilities(CameraTags::CameraAlignWithWorldUp, this);
		AccCurrentYawAxisTilt.SnapTo(0);
		bShouldExit = false;
		CurrentPitch = 0;
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		Player.UnblockCapabilities(CameraTags::CameraAlignWithWorldUp, this);
		CameraUser.ClearYawAxis(this);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if (AirBreakComp != nullptr)
		{
			if (AirBreakComp.bIsBreaking)
				bShouldExit = true;
		}

		const float CameraDeltaTime = Time::CameraDeltaSeconds;
		if (!bShouldExit)
		{
			RollCameraTowardsSteering(CameraDeltaTime);
		}
		else
		{
			AccCurrentYawAxisTilt.AccelerateTo(0, FlightSettings.CameraTiltDuration, DeltaTime);
		}

		CurrentPitch = Math::FInterpTo(CurrentPitch, -5, DeltaTime, 1.0);
		// This will tilt the camera using the current
		FRotator WantedRotation = CameraUser.WorldToLocalRotation(DragonComp.DesiredCameraRotation.Get());
		WantedRotation.Roll += AccCurrentYawAxisTilt.Value;
		WantedRotation.Pitch -= CurrentPitch; //John testing
		WantedRotation = CameraUser.LocalToWorldRotation(WantedRotation);
		CameraUser.SetYawAxis(WantedRotation.UpVector, this);
	}

	void RollCameraTowardsSteering(float DeltaTime)
	{
		FVector MovementInput = MoveComp.MovementInput;
		float SteeringAxisTilt = MovementInput.Y * FlightSettings.CameraTiltMax;
		AccCurrentYawAxisTilt.AccelerateTo(SteeringAxisTilt, FlightSettings.CameraTiltDuration, DeltaTime);
	}
}