class UBattlefieldHoverboardLoopCameraCapability : UHazePlayerCapability
{
	default CapabilityTags.Add(CameraTags::Camera);

	default CapabilityTags.Add(CapabilityTags::Input);
	default CapabilityTags.Add(CapabilityTags::StickInput);

    default DebugCategory = n"Hoverboard";

	default TickGroup = EHazeTickGroup::BeforeMovement;
	default TickGroupOrder = 1;

	UCameraUserComponent CameraUser;
	UBattlefieldHoverboardLoopComponent HoverboardLoopComp;
	UPlayerMovementComponent MoveComp;

	UBattlefieldHoverboardCameraControlSettings CameraControlSettings;
	
	const float YawAxisRotationDuration = 0.5;
	const float SplineFollowCameraRotationDuration = 2.0;

	FHazeAcceleratedVector AccYawAxis;
	FHazeAcceleratedRotator AccCameraRotation;
	FHazeAcceleratedRotator AccInputCameraRotation;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		CameraUser = UCameraUserComponent::Get(Player); 
		HoverboardLoopComp = UBattlefieldHoverboardLoopComponent::Get(Player);

		CameraControlSettings = UBattlefieldHoverboardCameraControlSettings::GetSettings(Player);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if(!CameraUser.CanControlCamera())
			return false;

		if(!HoverboardLoopComp.bIsInLoop)
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if(!CameraUser.CanControlCamera())
			return true;

		if(!HoverboardLoopComp.bIsInLoop)
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		Player.BlockCapabilities(CameraTags::CameraAlignWithWorldUp, this);
		Player.BlockCapabilities(CameraTags::CameraControl, this);

		AccYawAxis.SnapTo(FVector::UpVector);
		AccCameraRotation.SnapTo(CameraUser.GetViewRotation());
		AccInputCameraRotation.SnapTo(FRotator::ZeroRotator);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		Player.UnblockCapabilities(CameraTags::CameraAlignWithWorldUp, this);
		Player.UnblockCapabilities(CameraTags::CameraControl, this);

		CameraUser.ClearYawAxis(this);
	}
};