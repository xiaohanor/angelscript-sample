class UGravityBikeSplineDriverCameraCapability : UHazePlayerCapability
{
	default CapabilityTags.Add(CapabilityTags::Camera);
	default CapabilityTags.Add(GravityBikeSpline::CameraTags::GravityBikeSplineCamera);

	default DebugCategory = CameraTags::Camera;
	
	default TickGroup = EHazeTickGroup::Gameplay;
	default TickGroupOrder = 101;

	UGravityBikeSplineDriverComponent DriverComp;
	AGravityBikeSpline GravityBike;

	FHazeAcceleratedRotator AccCameraRelativeRotation;
	UCameraUserComponent CameraUser;

	UGravityBikeSplineCameraLookSplineComponent CameraLookSplineComp;
	FHazeAcceleratedFloat AccOffsetFromTurning;
	FHazeAcceleratedQuat AccDeltaCameraRotation;

	UCameraSettings CameraSettings;
	FHazeAcceleratedFloat AccIdealDistance;
	FHazeAcceleratedFloat AccFOV;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		DriverComp = UGravityBikeSplineDriverComponent::Get(Player);
		CameraUser = UCameraUserComponent::Get(Player);

		CameraSettings = UCameraSettings::GetSettings(Player);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if(DriverComp.GravityBike == nullptr)
			return false;

		if(DriverComp.GravityBike.GetActiveSplineActor() == nullptr)
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if(DriverComp.GravityBike == nullptr)
			return true;

		if(DriverComp.GravityBike.GetActiveSplineActor() == nullptr)
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		GravityBike = GravityBikeSpline::GetGravityBike();

		Player.ApplyViewSizeOverride(this, EHazeViewPointSize::Fullscreen, EHazeViewPointBlendSpeed::Instant);
		UCameraUserSettings::SetAllowCameraTrace(Player, false, this);

        if(GravityBike.Settings.DriverCamSettings != nullptr)
		    Player.ApplyCameraSettings(GravityBike.Settings.DriverCamSettings, 0.0, this, EHazeCameraPriority::Default);

		Player.BlockCapabilities(CameraTags::CameraControl, this);
		Player.BlockCapabilities(CameraTags::CameraAlignWithWorldUp, this);

		SnapToCurrentSpline();

		UCameraSettings::GetSettings(Player).PivotLagMaxMultiplier.Apply(FVector::ZeroVector, this, 0);

		GravityBike.OnSplineChanged.AddUFunction(this, n"OnSplineChanged");
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		Player.UnblockCapabilities(CameraTags::CameraControl, this);
		Player.UnblockCapabilities(CameraTags::CameraAlignWithWorldUp, this);

		CameraUser.ClearYawAxis(this);
		Player.ClearViewSizeOverride(this);
		Player.ClearCameraSettingsByInstigator(this);
		UCameraUserSettings::ClearAllowCameraTrace(Player, this);

		CameraSettings.IdealDistance.Clear(this, 1);
		CameraSettings.FOV.Clear(this, 1);

		UCameraSettings::GetSettings(Player).PivotLagMaxMultiplier.Clear(this);

		GravityBike.OnSplineChanged.Unbind(this, n"OnSplineChanged");
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		UGravityBikeSplineCameraLookSplineComponent NewCameraLookSplineComp = GravityBike.GetCameraLookSplineComponent();
		if(CameraLookSplineComp != NewCameraLookSplineComp)
		{
			OnCameraLookSplineCompChanged(CameraLookSplineComp, NewCameraLookSplineComp);
			CameraLookSplineComp = NewCameraLookSplineComp;
		}

		FQuat CameraRotation = GetSplineCameraRotation(CameraLookSplineComp);
		AccDeltaCameraRotation.AccelerateTo(FQuat::Identity, 2, DeltaTime);
		CameraRotation = AccDeltaCameraRotation.Value * CameraRotation;
		CameraUser.SetYawAxis(CameraRotation.UpVector, this);

		FRotator RelativeCameraRotation = CameraUser.WorldToLocalRotation(CameraRotation.Rotator());
		AccCameraRelativeRotation.AccelerateTo(RelativeCameraRotation, 1.0, DeltaTime);
		CameraUser.SetDesiredLocalRotation(AccCameraRelativeRotation.Value, this);

		const float CurrentDistanceAlongSpline = CameraLookSplineComp.SplineComp.GetClosestSplineDistanceToWorldLocation(GravityBike.ActorLocation);
		TOptional<FGravityBikeSplineCameraSettings> SplineCameraSettings = CameraLookSplineComp.GetCameraSettingsDistanceAlongSpline(CurrentDistanceAlongSpline);

		if(SplineCameraSettings.IsSet())
			ApplySplineCameraSettings(SplineCameraSettings.Value, DeltaTime);
	}

	void SnapToCurrentSpline()
	{
		CameraLookSplineComp = GravityBike.GetCameraLookSplineComponent();
		FQuat CameraRotation = GetSplineCameraRotation(CameraLookSplineComp);
		CameraUser.SetYawAxis(CameraRotation.UpVector, this);

		FRotator RelativeCameraRotation = CameraUser.WorldToLocalRotation(CameraRotation.Rotator());
		AccCameraRelativeRotation.SnapTo(RelativeCameraRotation);
		CameraUser.SetDesiredLocalRotation(RelativeCameraRotation, this);

		if(CameraLookSplineComp != nullptr)
			OnCameraLookSplineCompChanged(nullptr, CameraLookSplineComp);

		AccDeltaCameraRotation.SnapTo(FQuat::Identity);
		AccOffsetFromTurning.SnapTo(0);

		AccIdealDistance.SnapTo(CameraSettings.IdealDistance.Value);
		AccFOV.SnapTo(CameraSettings.FOV.Value);
	}

	void OnCameraLookSplineCompChanged(UGravityBikeSplineCameraLookSplineComponent OldCameraLookSplineComp, UGravityBikeSplineCameraLookSplineComponent NewCameraLookSplineComp)
	{
		if(OldCameraLookSplineComp != nullptr)
		{
			FQuat OldCameraRotation = GetSplineCameraRotation(OldCameraLookSplineComp);
			FQuat NewCameraRotation = GetSplineCameraRotation(NewCameraLookSplineComp);

			FQuat DeltaRotation = NewCameraRotation * OldCameraRotation.Inverse();
			AccDeltaCameraRotation.Value = DeltaRotation.Inverse() * AccDeltaCameraRotation.Value;
		}
	}

	FQuat GetSplineCameraRotation(UGravityBikeSplineCameraLookSplineComponent InCameraLookSplineComp) const
	{
		const float CurrentDistanceAlongSpline = InCameraLookSplineComp.SplineComp.GetClosestSplineDistanceToWorldLocation(GravityBike.ActorLocation);
		return InCameraLookSplineComp.GetCameraRotationAtDistanceAlongSpline(CurrentDistanceAlongSpline, GravityBike.Settings.SplineDirectionLead);
	}

	void ApplySplineCameraSettings(FGravityBikeSplineCameraSettings SplineCameraSettings, float DeltaTime)
	{
		AccIdealDistance.AccelerateTo(SplineCameraSettings.IdealDistance, 1, DeltaTime);
		AccFOV.AccelerateTo(SplineCameraSettings.FOV, 1, DeltaTime);

		CameraSettings.IdealDistance.Apply(AccIdealDistance.Value, this, 0, EHazeCameraPriority::High);
		CameraSettings.FOV.Apply(AccFOV.Value, this, 0, EHazeCameraPriority::Minimum);
	}

	UFUNCTION()
	private void OnSplineChanged(AGravityBikeSplineActor OldSpline, AGravityBikeSplineActor NewSpline, bool bSnap)
	{
		if(bSnap)
		{
			SnapToCurrentSpline();
		}
	}
}