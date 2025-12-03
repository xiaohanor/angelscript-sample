class UMagnetDroneCameraAlignToSurfaceCapability : UHazePlayerCapability
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

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		AttachedComp = UMagnetDroneAttachedComponent::Get(Player);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if(!AttachedComp.IsAttached())
			return false;

		if(!AttachedComp.IsCameraAlignedWithSurface())
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if(!AttachedComp.IsAttached())
			return true;

		if(!AttachedComp.IsCameraAlignedWithSurface())
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		UPlayerCameraSettings::SetAlignCameraWithWorldUpDuration(Player, AttachedComp.AttachedData.GetSurfaceComp().AlignCameraWithSurfaceDuration, this);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		UPlayerCameraSettings::ClearAlignCameraWithWorldUpDuration(Player, this);
	}
}