struct FGravityBikeFreeDriverDeathCameraActivateParams
{
	UHazeCameraSettingsDataAsset Settings;
};

class UGravityBikeFreeDriverDeathCameraCapability : UHazePlayerCapability
{
	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;
	
	default CapabilityTags.Add(CapabilityTags::Camera);
	default CapabilityTags.Add(GravityBikeFree::Tags::GravityBikeFree);
	default CapabilityTags.Add(GravityBikeFree::Tags::GravityBikeFreeCamera);

	default DebugCategory = CameraTags::Camera;
	
	default TickGroup = EHazeTickGroup::BeforeGameplay;
	default TickGroupOrder = 50;

	UGravityBikeFreeDriverComponent DriverComp;
	UGravityBikeFreeCameraDataComponent CameraDataComp;
	UCameraUserComponent CameraUserComp;

	AGravityBikeFree GravityBike;

	const float TRANSITION_DURATION = 5;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		DriverComp = UGravityBikeFreeDriverComponent::Get(Player);
		CameraDataComp = UGravityBikeFreeCameraDataComponent::Get(Player);
		CameraUserComp = UCameraUserComponent::Get(Player);

		GravityBike = DriverComp.GetOrSpawnGravityBike();
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate(FGravityBikeFreeDriverDeathCameraActivateParams& Params) const
	{
		if(CameraDataComp.HasAppliedDesiredRotation())
			return false;

		if(!GravityBike.GetDriver().IsPlayerDead())
			return false;

		if(!CameraDataComp.HasDeathSettings())
			return false;

		Params.Settings = CameraDataComp.GetDeathCameraSettings();
		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if(CameraDataComp.HasAppliedDesiredRotation())
			return true;

		if(!GravityBike.GetDriver().IsPlayerDead())
			return true;

		if(!CameraDataComp.HasDeathSettings())
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FGravityBikeFreeDriverDeathCameraActivateParams Params)
	{
		Player.ApplyCameraSettings(Params.Settings, TRANSITION_DURATION, this, EHazeCameraPriority::VeryHigh, 0);
		UCameraUserSettings::SetAllowCameraTrace(Player, false, this);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		Player.ClearCameraSettingsByInstigator(this, 0);
		UCameraUserSettings::ClearAllowCameraTrace(Player, this);
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
		// Face towards the ground
		FQuat Rotation = FQuat(GravityBike.ActorRightVector, Math::DegreesToRadians(30)) * CameraDataComp.GetBikeForwardTargetRotation(GravityBike.Settings.CameraLeadAmount);
		CameraDataComp.AccCameraRotation.AccelerateTo(Rotation, GravityBike.Settings.CameraFollowDuration, DeltaTime);
		CameraDataComp.AccYawAxisRollOffset.AccelerateTo(0, GravityBike.Settings.CameraRollResetDuration, DeltaTime);
		CameraDataComp.ApplyDesiredRotation(this);
		
		CameraDataComp.ResetCameraOffsetFromSpeed();
	}

	void TickRemote(float DeltaTime)
	{
		CameraDataComp.ApplyCrumbSyncedCameraOffset();
	}
}