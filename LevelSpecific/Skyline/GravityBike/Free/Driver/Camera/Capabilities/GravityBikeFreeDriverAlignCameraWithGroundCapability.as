class UGravityBikeFreeDriverAlignCameraWithGroundCapability : UHazePlayerCapability
{
	default NetworkMode = EHazeCapabilityNetworkMode::Local;

	default CapabilityTags.Add(CapabilityTags::Camera);
	default CapabilityTags.Add(GravityBikeFree::Tags::GravityBikeFree);
	default CapabilityTags.Add(GravityBikeFree::Tags::GravityBikeFreeCamera);

	default TickGroup = EHazeTickGroup::AfterGameplay;

	UGravityBikeFreeDriverComponent DriverComp;
	UGravityBikeFreeCameraDataComponent CameraDataComp;
	UCameraUserComponent CameraUserComp;

	AGravityBikeFree GravityBike;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		DriverComp = UGravityBikeFreeDriverComponent::Get(Player);
		CameraDataComp = UGravityBikeFreeCameraDataComponent::Get(Player);
		CameraUserComp = UCameraUserComponent::Get(Player);

		GravityBike = DriverComp.GetOrSpawnGravityBike();
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if(!HasControl())
			return false;

		if(!GravityBike.Settings.bAlignCameraWithGround)
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if(!GravityBike.Settings.bAlignCameraWithGround)
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		CameraDataComp.YawAxisBase.Apply(GravityBike.GetAcceleratedUp(), this);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		CameraDataComp.YawAxisBase.Clear(this);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		CameraDataComp.YawAxisBase.Apply(GravityBike.GetAcceleratedUp(), this);
	}
};