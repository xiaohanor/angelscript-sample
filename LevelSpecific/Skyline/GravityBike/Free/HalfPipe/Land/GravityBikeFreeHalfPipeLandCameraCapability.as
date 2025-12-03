class UGravityBikeFreeHalfPipeLandCameraCapability : UHazeCapability
{
	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;

	default CapabilityTags.Add(CapabilityTags::Camera);
	default CapabilityTags.Add(GravityBikeFree::HalfPipeTags::GravityBikeFreeHalfPipe);
	default CapabilityTags.Add(GravityBikeFree::HalfPipeTags::GravityBikeFreeHalfPipeLand);
	default CapabilityTags.Add(GravityBikeFree::HalfPipeTags::GravityBikeFreeHalfPipeCamera);

	default TickGroup = EHazeTickGroup::Gameplay;
	default TickGroupOrder = 50;

	AGravityBikeFree GravityBike;
	UGravityBikeFreeHalfPipeComponent HalfPipeComp;

	AHazePlayerCharacter Player;
	UGravityBikeFreeCameraDataComponent CameraDataComp;
	UCameraUserComponent CameraUser;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		GravityBike = Cast<AGravityBikeFree>(Owner);
		HalfPipeComp = UGravityBikeFreeHalfPipeComponent::Get(GravityBike);

		Player = GravityBike.GetDriver();
		CameraDataComp = UGravityBikeFreeCameraDataComponent::Get(Player);
		CameraUser = UCameraUserComponent::Get(Player);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if(!HalfPipeComp.bIsJumping)
			return false;

		if(HalfPipeComp.RotationState != EGravityBikeFreeHalfPipeRotationState::Land)
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if(!HalfPipeComp.bIsJumping)
			return true;

		if(HalfPipeComp.RotationState != EGravityBikeFreeHalfPipeRotationState::Land)
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		Player.BlockCapabilities(CameraTags::CameraControl, this);
		GravityBike.BlockCapabilities(GravityBikeFree::Tags::GravityBikeFreeCamera, this);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
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
		FVector DirOutFromCenter = GravityBike.ActorLocation - HalfPipeComp.JumpData.GetJumpCenterLocation();
		DirOutFromCenter = DirOutFromCenter.VectorPlaneProject(HalfPipeComp.JumpData.GetJumpTangent());
		DirOutFromCenter.Normalize();

		FQuat TargetRotation = FQuat::MakeFromXZ(GravityBike.ActorVelocity, HalfPipeComp.JumpData.GetTargetNormal());
		TargetRotation = FQuat(TargetRotation.RightVector, Math::DegreesToRadians(-30)) * TargetRotation;

		CameraDataComp.AccCameraRotation.AccelerateTo(TargetRotation, 1, DeltaTime);
		CameraDataComp.ApplyDesiredRotation(this);

		//CameraDataComp.ApplyCameraOffsetFromSpeed(DeltaTime);
	}

	void TickRemote(float DeltaTime)
	{
		//CameraDataComp.ApplyCrumbSyncedCameraOffset();
	}
}