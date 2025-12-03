class UPlayerTreeGuardianRangedInteractionFoundTargetCameraCapability : UHazePlayerCapability
{
	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;
	default TickGroup = EHazeTickGroup::Movement;

	UTundraPlayerShapeshiftingComponent ShapeshiftingComp;
	UTundraPlayerTreeGuardianComponent TreeGuardianComp;
	UCameraSettings CameraSettings;

	const float BlendInTime = 3.0;
	const float BlendOutTime = 3.0;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		ShapeshiftingComp = UTundraPlayerShapeshiftingComponent::Get(Player);
		TreeGuardianComp = UTundraPlayerTreeGuardianComponent::Get(Player);
		CameraSettings = UCameraSettings::GetSettings(Player);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		// if(ShapeshiftingComp.CurrentShapeType != ETundraShapeshiftShape::Big)
		// 	return false;

		if(TreeGuardianComp.CurrentlyFoundRangedInteractionTargetable == nullptr)
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		// if(ShapeshiftingComp.CurrentShapeType != ETundraShapeshiftShape::Big)
		// 	return true;

		if(TreeGuardianComp.CurrentlyFoundRangedInteractionTargetable == nullptr)
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		if(TreeGuardianComp.CurrentRangedGrapplePoint == nullptr && TreeGuardianComp.CameraSettingsWhenFoundRangedInteraction != nullptr)
			Player.ApplyCameraSettings(TreeGuardianComp.CameraSettingsWhenFoundRangedInteraction, BlendInTime, this, EHazeCameraPriority::High);
		else if(TreeGuardianComp.CurrentRangedGrapplePoint != nullptr && TreeGuardianComp.CameraSettingsWhenAttachedFoundRangedInteraction != nullptr)
			Player.ApplyCameraSettings(TreeGuardianComp.CameraSettingsWhenAttachedFoundRangedInteraction, BlendInTime, this, EHazeCameraPriority::High);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		Player.ClearCameraSettingsByInstigator(this, BlendOutTime);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		float CurrentIdealDistance = CameraSettings.IdealDistance.GetValue();
		const float TreeGuardianIdealDistance = 1000.0;
		float ManualFraction = CurrentIdealDistance / TreeGuardianIdealDistance;
		Player.ApplyManualFractionToCameraSettings(ManualFraction, this);
	}
}