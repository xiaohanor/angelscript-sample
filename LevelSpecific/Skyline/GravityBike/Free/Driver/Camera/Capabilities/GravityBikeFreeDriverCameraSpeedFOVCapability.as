class UGravityBikeFreeDriverCameraSpeedFOVCapability : UHazePlayerCapability
{
	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;

	default CapabilityTags.Add(CapabilityTags::Camera);
	default CapabilityTags.Add(GravityBikeFree::Tags::GravityBikeFree);
	default CapabilityTags.Add(GravityBikeFree::Tags::GravityBikeFreeCamera);

	default TickGroup = EHazeTickGroup::Gameplay;
	default TickGroupOrder = 100;

	UGravityBikeFreeDriverComponent DriverComp;
	UGravityBikeFreeCameraDataComponent CameraDataComp;
	UCameraSettings CameraSettings;

	AGravityBikeFree GravityBike;
	UGravityBikeFreeMovementComponent MoveComp;

	FHazeAcceleratedFloat AccSpeedAlpha;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		DriverComp = UGravityBikeFreeDriverComponent::Get(Player);
		CameraDataComp = UGravityBikeFreeCameraDataComponent::Get(Player);
		CameraSettings = UCameraSettings::GetSettings(Player);
		
		GravityBike = DriverComp.GetOrSpawnGravityBike();
		MoveComp = GravityBike.MoveComp;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if(GravityBike.IsDrifting())
			return false;

		if(GravityBike.IsBoosting())
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if(GravityBike.IsDrifting())
			return true;

		if(GravityBike.IsBoosting())
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		AccSpeedAlpha.SnapTo(GetSpeedAlpha());
		CameraSettings.IdealDistance.ApplyAsAdditive(GravityBike.Settings.ThrottleDistanceAdditive, this, 1, EHazeCameraPriority::High);
		CameraSettings.FOV.ApplyAsAdditive(GravityBike.Settings.ThrottleFOVAdditive, this, 1, EHazeCameraPriority::High);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		CameraSettings.IdealDistance.Clear(this, 1);
		CameraSettings.FOV.Clear(this, 1);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		const float TargetSpeedAlpha = GetSpeedAlpha();
		if(TargetSpeedAlpha > AccSpeedAlpha.Value)
			AccSpeedAlpha.AccelerateTo(TargetSpeedAlpha, GravityBike.Settings.ThrottleCameraAccelerateDuration, DeltaTime);
		else
			AccSpeedAlpha.AccelerateTo(TargetSpeedAlpha, GravityBike.Settings.NoThrottleCameraAccelerateDuration, DeltaTime);

		CameraSettings.IdealDistance.SetManualFraction(AccSpeedAlpha.Value, this);
		CameraSettings.FOV.SetManualFraction(AccSpeedAlpha.Value, this);
	}

	float GetSpeedAlpha() const
	{
		float SpeedAlpha = Math::GetPercentageBetweenClamped(GravityBike.Settings.MinimumSpeed, GravityBike.Settings.MaxSpeed, MoveComp.GetForwardSpeed());
		return SpeedAlpha;
	}
};