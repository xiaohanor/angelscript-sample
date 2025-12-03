class UGravityBikeFreeHalfPipeAimCameraCapability : UHazeCapability
{
	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;

	default CapabilityTags.Add(CapabilityTags::Camera);
	default CapabilityTags.Add(GravityBikeFree::HalfPipeTags::GravityBikeFreeHalfPipe);
	default CapabilityTags.Add(GravityBikeFree::HalfPipeTags::GravityBikeFreeHalfPipeAim);
	default CapabilityTags.Add(GravityBikeFree::HalfPipeTags::GravityBikeFreeHalfPipeCamera);

	default TickGroup = EHazeTickGroup::Gameplay;
	default TickGroupOrder = 50;

	AGravityBikeFree GravityBike;
	UGravityBikeFreeHalfPipeComponent HalfPipeComp;

	AHazePlayerCharacter Player;
	UGravityBikeFreeCameraDataComponent CameraDataComp;
	UCameraUserComponent CameraUser;
	UCameraSettings CameraSettings;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		GravityBike = Cast<AGravityBikeFree>(Owner);
		HalfPipeComp = UGravityBikeFreeHalfPipeComponent::Get(GravityBike);

		Player = GravityBike.GetDriver();
		CameraDataComp = UGravityBikeFreeCameraDataComponent::Get(Player);
		CameraUser = UCameraUserComponent::Get(Player);
		CameraSettings = UCameraSettings::GetSettings(Player);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if(!HalfPipeComp.bIsJumping)
			return false;

		if(HalfPipeComp.RotationState != EGravityBikeFreeHalfPipeRotationState::Aim && HalfPipeComp.RotationState != EGravityBikeFreeHalfPipeRotationState::BackFlip)
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if(!HalfPipeComp.bIsJumping)
			return true;

		if(HalfPipeComp.RotationState != EGravityBikeFreeHalfPipeRotationState::Aim && HalfPipeComp.RotationState != EGravityBikeFreeHalfPipeRotationState::BackFlip)
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		CameraSettings.FOV.ApplyAsAdditive(-20, this, 1);

		Player.BlockCapabilities(CameraTags::CameraControl, this);
		GravityBike.BlockCapabilities(GravityBikeFree::Tags::GravityBikeFreeCamera, this);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		CameraSettings.FOV.Clear(this);

		Player.UnblockCapabilities(CameraTags::CameraControl, this);
		GravityBike.UnblockCapabilities(GravityBikeFree::Tags::GravityBikeFreeCamera, this);
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
		FQuat LookAtCenter = FQuat::MakeFromX(HalfPipeComp.JumpData.GetJumpCenterLocation() - GravityBike.ActorLocation);
		CameraDataComp.AccCameraRotation.AccelerateTo(LookAtCenter, 1, DeltaTime);
		CameraDataComp.ApplyDesiredRotation(this);

		//CameraDataComp.ApplyCameraOffsetFromSpeed(DeltaTime);
	}

	void TickRemote(float DeltaTime)
	{
		//CameraDataComp.ApplyCrumbSyncedCameraOffset();
	}
}