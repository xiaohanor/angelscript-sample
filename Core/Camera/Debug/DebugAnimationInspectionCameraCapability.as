asset DebugAnimationInspectionCameraSettings of UHazeCameraSpringArmSettingsDataAsset
{
	SpringArmSettings.bUseIdealDistance = true;
	SpringArmSettings.IdealDistance = 200.0;

	SpringArmSettings.bUsePivotOffset = true;
	SpringArmSettings.PivotOffset = FVector(0.0, 0.0, 100.0);

	SpringArmSettings.bUseCameraOffset = true;
	SpringArmSettings.CameraOffset = FVector::ZeroVector;

	SpringArmSettings.bUseCameraOffsetOwnerSpace = true;
	SpringArmSettings.CameraOffset = FVector::ZeroVector;
}

#if TEST
class UDebugAnimationInspectionCameraCapability : UHazePlayerCapability
{
	default CapabilityTags.Add(CameraTags::CameraDebugCamera);
	default TickGroup = EHazeTickGroup::LastDemotable; // AFter camera view is finalized
    default DebugCategory = n"Debug";

	UCameraDebugUserComponent DebugUser = nullptr;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		FHazeDevInputInfo ToggleInfo;
		ToggleInfo.Name = n"Toggle Animation Inspection Camera";
		ToggleInfo.Category = n"Animation";
		ToggleInfo.AddKey(EKeys::I);
		ToggleInfo.AddKey(EKeys::Gamepad_RightShoulder);
		ToggleInfo.OnTriggered.BindUFunction(this, n"ToggleDebugAnimationInspection");
		Player.RegisterDevInput(ToggleInfo);

		DebugUser = UCameraDebugUserComponent::GetOrCreate(Player);
	}

	UFUNCTION()
	private void ToggleDebugAnimationInspection()
	{
		DebugUser.bUsingDebugAnimationInspection = !DebugUser.bUsingDebugAnimationInspection;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if(!HasControl())
			return false;
		
		if (!DebugUser.bUsingDebugAnimationInspection)
			return false;
		
		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (!DebugUser.bUsingDebugAnimationInspection)
			return true; 

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		// Other player should always keep the same state as we do
		UCameraDebugUserComponent OtherDebugUser = 	UCameraDebugUserComponent::Get(Player.OtherPlayer);
		OtherDebugUser.bUsingDebugAnimationInspection = true;

		// Activate default camera with animation inspection settings
		Player.ApplyCameraSettings(DebugAnimationInspectionCameraSettings, 2, this, EHazeCameraPriority::Debug);
		// Player.ActivateCamera(UHazeCameraComponent::Get(Player), 2.0, this, EHazeCameraPriority::High); // Don't override cutscene cams!
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		// Other player should always keep the same state as we do
		UCameraDebugUserComponent OtherDebugUser = 	UCameraDebugUserComponent::Get(Player.OtherPlayer);
		OtherDebugUser.bUsingDebugAnimationInspection = false;

		// Player.DeactivateCameraByInstigator(this);
		Player.ClearCameraSettingsByInstigator(this);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if (Player.IsMio())
			PrintToScreenScaled("Animation Inspection camera active! Toggle using 'V + I' on keyboard or in camera dev menu.", 0.0, FLinearColor::Red, 1.2);
	}
}	
#endif
