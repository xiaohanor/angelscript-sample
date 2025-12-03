class UMagnetDroneCameraAttachedWallClampsCapability : UHazePlayerCapability
{
	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;
	default DebugCategory = Drone::DebugCategory;

	default CapabilityTags.Add(CapabilityTags::Camera);
	default CapabilityTags.Add(PrisonTags::Prison);
	default CapabilityTags.Add(PrisonTags::Drones);
	default CapabilityTags.Add(MagnetDroneTags::MagnetDrone);
	default CapabilityTags.Add(MagnetDroneTags::MagnetDroneCameraAttachedWallClamps);

	default TickGroup = EHazeTickGroup::Movement;
	default TickGroupOrder = 101;

	UMagnetDroneAttachedComponent AttachedComp;
	UCameraUserComponent CameraUser;
	UHazeMovementComponent MoveComp;

	FHazeAcceleratedFloat AccClampAngle;
	FHazeAcceleratedRotator AccRotationFacingToWall;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		AttachedComp = UMagnetDroneAttachedComponent::Get(Player);
		CameraUser = UCameraUserComponent::Get(Player);
		MoveComp = UHazeMovementComponent::Get(Player);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if(!ShouldClampCameraOnWall())
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if(!ShouldClampCameraOnWall())
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		// Start with clamps fully disengaged
		AccClampAngle.SnapTo(180.0);
		AccRotationFacingToWall.SnapTo(GetRotationFacingInToWall());

		ApplyClamps();

		Player.BlockCapabilities(CapabilityTags::FindOtherPlayer, this);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		CameraUser.CameraSettings.Clamps.Clear(this);

		Player.UnblockCapabilities(CapabilityTags::FindOtherPlayer, this);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(const float DeltaTime)
	{
		// Smoothly clamp more and more, to force the player to a better viewing angle away from the wall
		AccClampAngle.AccelerateTo(MagnetDrone::MagnetCameraClampAngle, 2, DeltaTime);
		AccRotationFacingToWall.AccelerateTo(GetRotationFacingInToWall(), 1, DeltaTime);

		ApplyClamps();
	}

	bool ShouldClampCameraOnWall() const
	{
		if(!AttachedComp.IsAttached())
			return false;

		// If the ground normal is almost vertical, don't clamp the camera
		if(Math::Abs(AttachedComp.CalculateWorldUp().Z) > 0.7)
			return false;

		if(AttachedComp.IsCameraAlignedWithSurface())
			return false;

		if(AttachedComp.AttachedData.CameraType != EMagneticSurfaceComponentCameraType::AutomaticWall)
			return false;

		return true;
	}

	void ApplyClamps()
	{
		FHazeCameraClampSettings ClampSettings;
		ClampSettings.ApplyWorldSpaceCenterOffset(AccRotationFacingToWall.Value);
		ClampSettings.ApplyClampsYaw(AccClampAngle.Value, AccClampAngle.Value);
		CameraUser.CameraSettings.Clamps.Apply(ClampSettings, this, 0, EHazeCameraPriority::Medium);
	}

	FRotator GetRotationFacingInToWall()
	{
		FVector OutFromWall = AttachedComp.CalculateWorldUp().VectorPlaneProject(FVector::UpVector).GetSafeNormal();
		return FRotator::MakeFromXZ(-OutFromWall, FVector::UpVector);
	}
}	