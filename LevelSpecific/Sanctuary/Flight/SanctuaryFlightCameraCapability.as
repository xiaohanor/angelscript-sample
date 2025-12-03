class USanctuaryFlightCameraCapability : UHazePlayerCapability
{
	default CapabilityTags.Add(CameraTags::Camera);
	default CapabilityTags.Add(n"Flight");

	default DebugCategory = n"Movement";
	default TickGroup = EHazeTickGroup::AfterPhysics;
	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;

	USanctuaryFlightComponent FlightComp;
	USanctuaryFlightSettings Settings;
	
	FHazeAcceleratedVector AccCameraOffset;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		FlightComp = USanctuaryFlightComponent::Get(Player);
		Settings = USanctuaryFlightSettings::GetSettings(Owner);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (!FlightComp.bFlying)
			return false;
		return true;		
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (!FlightComp.bFlying)
			return true;
		return false;		
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		if (FlightComp.CameraSettings != nullptr)
			Player.ApplyCameraSettings(FlightComp.CameraSettings, 2, this, SubPriority = 60);

		auto POI = Player.CreatePointOfInterest();
		POI.FocusTarget.SetFocusToComponent(FlightComp.Center);
		POI.Settings.InputPauseTime = 0;
		POI.Apply(this, 2);
		AccCameraOffset.SnapTo(FVector::ZeroVector);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		Player.ClearCameraSettingsByInstigator(this);
		Player.ClearPointOfInterestByInstigator(this);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		FVector2D Input = GetAttributeVector2D(AttributeVectorNames::MovementRaw);				
		FVector TargetCameraOffset = FVector(0.0, Input.Y * Settings.CameraOffsetRight, Input.X * Settings.CameraOffsetUp);
		AccCameraOffset.AccelerateTo(TargetCameraOffset, 2.0, DeltaTime);

		UCameraSettings::GetSettings(Player).CameraOffset.ApplyAsAdditive(AccCameraOffset.Value, this);

		// FHazeCameraSpringArmSettings CameraSettings;
		// CameraSettings.ApplyCameraOffset(AccCameraOffset.Value, true);
		// Player.ApplyCameraSpringArmSettings(CameraSettings, 0, this, EHazeCameraPriority::Medium);
		//SceneView::SetSplitScreenMode(EHazeSplitScreenMode::Vertical);
	}
}