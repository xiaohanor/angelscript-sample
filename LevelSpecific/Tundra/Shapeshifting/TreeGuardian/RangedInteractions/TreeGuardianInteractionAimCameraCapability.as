class UTundraPlayerTreeGuardianRangedInteractionAimingCameraCapability : UHazePlayerCapability
{
	default TickGroup = EHazeTickGroup::Movement;
	default TickGroupOrder = 100;

	default CapabilityTags.Add(TundraRangedInteractionTags::RangedInteractionAiming);
	default BlockExclusionTags.Add(TundraRangedInteractionTags::RangedInteractionAimingCameraExclusion);

	UTundraPlayerShapeshiftingComponent ShapeshiftingComp;
	UTundraPlayerTreeGuardianComponent TreeGuardianComp;
	UPlayerAimingComponent AimComp;

	UHazeCameraSpringArmSettingsDataAsset CurrentAppliedCameraSettings;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		ShapeshiftingComp = UTundraPlayerShapeshiftingComponent::Get(Player);
		TreeGuardianComp = UTundraPlayerTreeGuardianComponent::Get(Player);
		AimComp = UPlayerAimingComponent::Get(Player);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if(!HasControl())
			return false;

		if(!AimComp.IsAiming(TreeGuardianComp))
			return false;

		if(ShapeshiftingComp.CurrentShapeType != ETundraShapeshiftShape::Big)
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if(!AimComp.IsAiming(TreeGuardianComp) && !Player.IsCapabilityTagBlocked(TundraRangedInteractionTags::RangedInteractionAiming))
			return true;

		if(ShapeshiftingComp.CurrentShapeType != ETundraShapeshiftShape::Big)
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		ClearCameraSettings();
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if(TreeGuardianComp.CurrentRangedGrapplePoint == nullptr && TreeGuardianComp.CameraSettingsWhenAiming != nullptr)
			TryApplyCameraSettings(TreeGuardianComp.CameraSettingsWhenAiming);
			
		else if(TreeGuardianComp.CurrentRangedGrapplePoint != nullptr && TreeGuardianComp.CameraSettingsWhenAttachedAiming != nullptr)
			TryApplyCameraSettings(TreeGuardianComp.CameraSettingsWhenAttachedAiming);
	}

	void TryApplyCameraSettings(UHazeCameraSpringArmSettingsDataAsset CameraSettings)
	{
		// These camera settings are already applied so early out.
		if(CurrentAppliedCameraSettings == CameraSettings)
			return;

		// There is already another camera setting applied so clear this first!
		if(CurrentAppliedCameraSettings != nullptr)
			ClearCameraSettings();

		// Apply the settings!
		Player.ApplyCameraSettings(CameraSettings, 1.5, this);
		CurrentAppliedCameraSettings = CameraSettings;
	}

	void ClearCameraSettings()
	{
		Player.ClearCameraSettingsByInstigator(this, 1.5);
		CurrentAppliedCameraSettings = nullptr;
	}
}