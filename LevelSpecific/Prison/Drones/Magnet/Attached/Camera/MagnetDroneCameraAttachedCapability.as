class UMagnetDroneCameraAttachedCapability : UHazePlayerCapability
{
	// Local since what we are attached to is synced
	default NetworkMode = EHazeCapabilityNetworkMode::Local;
	default DebugCategory = Drone::DebugCategory;

	default CapabilityTags.Add(CapabilityTags::Camera);
	default CapabilityTags.Add(PrisonTags::Prison);
	default CapabilityTags.Add(PrisonTags::Drones);
	default CapabilityTags.Add(MagnetDroneTags::MagnetDrone);

	default TickGroup = EHazeTickGroup::Movement;
	default TickGroupOrder = 101;

	UMagnetDroneComponent DroneComp;
	UMagnetDroneAttachedComponent AttachedComp;
	UCameraUserComponent CameraUser;
	UMagnetDroneJumpComponent JumpComp;
	UMagnetDroneChainJumpComponent ChainJumpComp;
	UHazeMovementComponent MoveComp;

	FHazeAcceleratedFloat AccOffsetDistance;
	FHazeAcceleratedQuat AccWorldUp;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		DroneComp = UMagnetDroneComponent::Get(Player);
		AttachedComp = UMagnetDroneAttachedComponent::Get(Player);
		CameraUser = UCameraUserComponent::Get(Player);
		JumpComp = UMagnetDroneJumpComponent::Get(Player);
		ChainJumpComp = UMagnetDroneChainJumpComponent::Get(Player);
		MoveComp = UHazeMovementComponent::Get(Player);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if(!AttachedComp.IsAttached())
			return false;

		if(!ShouldUseAttachedCamera())
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if(!AttachedComp.IsAttached())
			return true;

		if(!ShouldUseAttachedCamera())
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		Player.ApplyCameraSettings(DroneComp.Settings.CamSettings_Attached, 0.2, this, SubPriority = 101);
		
		AccWorldUp.SnapTo(FQuat::MakeFromX(AttachedComp.CalculateWorldUp()));
		
		if(!ChainJumpComp.WasChainJumpingThisFrame())
			AccOffsetDistance.SnapTo(0);

		Player.BlockCapabilities(CapabilityTags::FindOtherPlayer, this);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		Player.ClearCameraSettingsByInstigator(this, 1.0);

		Player.UnblockCapabilities(CapabilityTags::FindOtherPlayer, this);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		AccWorldUp.AccelerateTo(FQuat::MakeFromX(AttachedComp.CalculateWorldUp()), 1, DeltaTime);
		AccOffsetDistance.AccelerateTo(MagnetDrone::PushOutCameraDistance, 1, DeltaTime);

		// Move the camera pivot out from the wall
		// const FVector SurfaceNormal = AccWorldUp.Value.ForwardVector;

		// auto CameraSettings = UCameraSettings::GetSettings(Player);
		// CameraSettings.WorldPivotOffset.Apply(SurfaceNormal * AccOffsetDistance.Value, this, Priority = EHazeCameraPriority::High);
	}

	bool ShouldUseAttachedCamera() const
	{
		if(!AttachedComp.IsAttached())
			return false;

		switch(AttachedComp.AttachedData.CameraType)
		{
			case EMagneticSurfaceComponentCameraType::AutomaticWall:
				return true;

			case EMagneticSurfaceComponentCameraType::NoAutomaticWallCamera:
				return true;

			case EMagneticSurfaceComponentCameraType::AlignWithSurface:
				return false;

			case EMagneticSurfaceComponentCameraType::ActivateCamera:
			{
				if(AttachedComp.AttachedData.IsSurface())
				{
					return AttachedComp.AttachedData.GetSurfaceComp().CameraActor == nullptr;
				}
				else if(AttachedComp.AttachedData.IsSocket())
				{
					return AttachedComp.AttachedData.GetSocketComp().CameraActor == nullptr;
				}
			}
		}

		return false;
	}
}	