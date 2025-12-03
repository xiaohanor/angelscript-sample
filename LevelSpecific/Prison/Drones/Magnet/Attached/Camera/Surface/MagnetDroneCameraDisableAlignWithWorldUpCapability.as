class UMagnetDroneCameraDisableAlignWithWorldUpCapability : UHazePlayerCapability
{
	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;
	default DebugCategory = Drone::DebugCategory;

	default CapabilityTags.Add(CapabilityTags::Camera);
	default CapabilityTags.Add(PrisonTags::Prison);
	default CapabilityTags.Add(PrisonTags::Drones);
	default CapabilityTags.Add(MagnetDroneTags::MagnetDrone);

	default TickGroup = EHazeTickGroup::Gameplay;
	default TickGroupOrder = 100;

	UMagnetDroneAttachedComponent AttachedComp;
	UCameraUserComponent CameraUserComp;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		AttachedComp = UMagnetDroneAttachedComponent::Get(Player);
		CameraUserComp = UCameraUserComponent::Get(Player);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if(AttachedComp.IsAttachedToSurface())
		{
			if(AttachedComp.AttachedData.GetSurfaceComp().CameraType == EMagneticSurfaceComponentCameraType::AlignWithSurface)
				return false;
		}

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if(AttachedComp.IsAttachedToSurface())
		{
			if(AttachedComp.AttachedData.GetSurfaceComp().CameraType == EMagneticSurfaceComponentCameraType::AlignWithSurface)
				return true;
		}

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		// block the native camera alignment
		Player.BlockCapabilities(CameraTags::CameraAlignWithWorldUp, this);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		Player.UnblockCapabilities(CameraTags::CameraAlignWithWorldUp, this);
	}
}