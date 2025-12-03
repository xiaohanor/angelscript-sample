class UGravityBikeSplineCameraSpeedFOVCapability : UHazePlayerCapability
{
	default CapabilityTags.Add(CapabilityTags::Camera);
	default CapabilityTags.Add(GravityBikeSpline::CameraTags::GravityBikeSplineCamera);
	default CapabilityTags.Add(GravityBikeSpline::CameraTags::GravityBikeSplineCameraSpeedFOV);

	default DebugCategory = CameraTags::Camera;
	
	default TickGroup = EHazeTickGroup::Gameplay;
	default TickGroupOrder = 102;

	UGravityBikeSplineDriverComponent DriverComp;
	AGravityBikeSpline GravityBike;
	FHazeAcceleratedFloat AccSpeedAlpha;

	UCameraUserComponent CameraUser;
	float CachedThrottle;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		DriverComp = UGravityBikeSplineDriverComponent::Get(Player);
		CameraUser = UCameraUserComponent::Get(Player);
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
		GravityBike = DriverComp.GravityBike;
		
		AccSpeedAlpha.SnapTo(GetThrottleAlpha());
		UCameraSettings::GetSettings(Player).IdealDistance.ApplyAsAdditive(GravityBike.Settings.NoThrottleDistanceAdditive, this, 1);
		UCameraSettings::GetSettings(Player).FOV.ApplyAsAdditive(GravityBike.Settings.NoThrottleFOVAdditive, this, 0, EHazeCameraPriority::Default);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		UCameraSettings::GetSettings(Player).IdealDistance.Clear(this, 0.2);
		UCameraSettings::GetSettings(Player).FOV.Clear(this, 0.2);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		const float TargetThrottleAlpha = GetThrottleAlpha();
		if(TargetThrottleAlpha > AccSpeedAlpha.Value)
			AccSpeedAlpha.AccelerateTo(TargetThrottleAlpha, GravityBike.Settings.ThrottleCameraAccelerateDuration, DeltaTime);
		else
			AccSpeedAlpha.AccelerateTo(TargetThrottleAlpha, GravityBike.Settings.NoThrottleCameraAccelerateDuration, DeltaTime);

		UCameraSettings::GetSettings(Player).IdealDistance.SetManualFraction(AccSpeedAlpha.Value, this);
		UCameraSettings::GetSettings(Player).FOV.SetManualFraction(AccSpeedAlpha.Value, this);
	}

	float GetThrottle()
	{
		if(GravityBike.IsAirborne.Get())
			CachedThrottle = Math::Max(CachedThrottle, GravityBike.Input.GetStickyThrottle());
		else
			CachedThrottle = GravityBike.Input.GetStickyThrottle();

		return CachedThrottle;
	}

	float GetThrottleAlpha()
	{
		return 1.0 - GetThrottle();
	}
};