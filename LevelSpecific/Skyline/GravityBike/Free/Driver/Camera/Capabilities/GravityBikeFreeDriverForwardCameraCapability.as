class UGravityBikeFreeDriverForwardCameraCapability : UHazePlayerCapability
{
	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;

	default CapabilityTags.Add(CapabilityTags::Camera);
	default CapabilityTags.Add(GravityBikeFree::Tags::GravityBikeFree);
	default CapabilityTags.Add(GravityBikeFree::Tags::GravityBikeFreeCamera);

	default DebugCategory = CameraTags::Camera;
	
	default TickGroup = EHazeTickGroup::Gameplay;
	default TickGroupOrder = 140;

	UGravityBikeFreeDriverComponent DriverComp;
	UGravityBikeFreeCameraDataComponent CameraDataComp;

	AGravityBikeFree GravityBike;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		DriverComp = UGravityBikeFreeDriverComponent::Get(Player);
		CameraDataComp = UGravityBikeFreeCameraDataComponent::Get(Player);

		GravityBike = DriverComp.GetOrSpawnGravityBike();
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if(CameraDataComp.HasAppliedDesiredRotation())
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if(CameraDataComp.HasAppliedDesiredRotation())
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if(HasControl())
			TickControl(DeltaTime);
		else
			TickRemote(DeltaTime);
	}

	void TickControl(float DeltaTime)
	{
		// Automatically face the camera towards a direction
		FQuat ForwardRotation = CameraDataComp.GetBikeForwardTargetRotation(GravityBike.Settings.CameraLeadAmount);
		CameraDataComp.AccCameraRotation.AccelerateTo(ForwardRotation, GravityBike.Settings.CameraFollowDuration, DeltaTime);

		//CameraDataComp.AccCameraRoll.AccelerateTo(0, 2, DeltaTime);
		CameraDataComp.AccYawAxisRollOffset.AccelerateTo(
			GravityBike.AnimationData.AngularSpeedAlpha * -GravityBike.Settings.CameraRollMultiplier,
			GravityBike.Settings.CameraRollDuration,
			DeltaTime
		);

		CameraDataComp.ApplyDesiredRotation(this);

		CameraDataComp.ApplyCameraOffsetFromSpeed(DeltaTime);
	}

	void TickRemote(float DeltaTime)
	{
		CameraDataComp.ApplyCrumbSyncedCameraOffset();
	}
};