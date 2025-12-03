class UPlayerAdjustCameraDistanceBySpeedCapability : UHazePlayerCapability
{
	default CapabilityTags.Add(n"Camera");

	default DebugCategory = n"Movement";
	
	default TickGroup = EHazeTickGroup::LastMovement;
	default TickGroupOrder = 180;

	UPROPERTY()
	UHazeCameraSpringArmSettingsDataAsset SprintCameraSetting;

	const float MinimumSpeed = 300.0;
	const float MaximumSpeed = 1000.0;

	FHazeAcceleratedFloat AcceleratedCameraSettingAlpha;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		AcceleratedCameraSettingAlpha.SnapTo(0.0);
		Player.ApplyCameraSettings(SprintCameraSetting, 0.2, this, EHazeCameraPriority::VeryHigh);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		Player.ClearCameraSettingsByInstigator(this);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		const float Speed = Owner.ActorVelocity.Size();
		float Alpha = Math::Clamp((Speed - MinimumSpeed) / (MaximumSpeed - MinimumSpeed), 0.0, 1.0);

		//Alpha = 0.0;

		const float AcceleratedDuration = Player.ActorVelocity.IsNearlyZero(20.0) ? 3.0 : 5.0;
		AcceleratedCameraSettingAlpha.AccelerateTo(Alpha, AcceleratedDuration, DeltaTime);

		PrintToScreenScaled("Target Alpha: " + Alpha, 0.0, FLinearColor::LucBlue);
		PrintToScreenScaled("Accelerated Alpha: " + AcceleratedCameraSettingAlpha.Value, 0.0, FLinearColor::Green);

		//float BlendSettings = float::ManualFraction(AcceleratedCameraSettingAlpha.Value, 0.2);
		Player.ApplyManualFractionToCameraSettings(AcceleratedCameraSettingAlpha.Value, this);
	}
}