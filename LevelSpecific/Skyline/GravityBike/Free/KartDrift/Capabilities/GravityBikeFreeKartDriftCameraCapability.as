class UGravityBikeFreeKartDriftCameraCapability : UHazeCapability
{
	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;

	default CapabilityTags.Add(CapabilityTags::Camera);
	default CapabilityTags.Add(GravityBikeFree::Tags::GravityBikeFreeDrift);
	default DebugCategory = CameraTags::Camera;
	
	default TickGroup = EHazeTickGroup::Gameplay;
	default TickGroupOrder = 100;

	AGravityBikeFree GravityBike;
	UGravityBikeFreeKartDriftComponent KartDriftComp;
	
	UGravityBikeFreeCameraDataComponent CameraDataComp;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		GravityBike = Cast<AGravityBikeFree>(Owner);
		KartDriftComp = UGravityBikeFreeKartDriftComponent::Get(GravityBike);

		CameraDataComp = UGravityBikeFreeCameraDataComponent::Get(GravityBike.GetDriver());
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if(CameraDataComp.HasAppliedDesiredRotation())
			return false;

		if(!KartDriftComp.IsDrifting())
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if(CameraDataComp.HasAppliedDesiredRotation())
			return true;

		if(!KartDriftComp.IsDrifting())
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		if(KartDriftComp.Settings.bUseDriftCamera)
			GravityBike.BlockCapabilities(GravityBikeFree::Tags::GravityBikeFreeCameraInput, this);

		GravityBike.GetDriver().ApplyCameraSettings(KartDriftComp.DriftCameraSettings, 2, this, EHazeCameraPriority::VeryHigh);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		if(KartDriftComp.Settings.bUseDriftCamera)
			GravityBike.UnblockCapabilities(GravityBikeFree::Tags::GravityBikeFreeCameraInput, this);

		GravityBike.GetDriver().ClearCameraSettingsByInstigator(this, 1);
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
		if(KartDriftComp.Settings.bUseDriftCamera)
		{
			// Rotate towards bike forward when drifting
			const float CameraYawLead = KartDriftComp.GetSteerIntoDriftFactor(false) * KartDriftComp.Settings.CameraLeadAmount;
			FQuat Rotation = FQuat(FVector::UpVector, Math::DegreesToRadians(CameraYawLead));
			Rotation *= GravityBike.ActorQuat;

			CameraDataComp.AccCameraRotation.AccelerateTo(Rotation, KartDriftComp.Settings.CameraFollowDuration, DeltaTime);
			CameraDataComp.ApplyDesiredRotation(this);

			CameraDataComp.ResetCameraOffsetFromSpeed();
		}
	}

	void TickRemote(float DeltaTime)
	{
		CameraDataComp.ApplyCrumbSyncedCameraOffset();
	}
};