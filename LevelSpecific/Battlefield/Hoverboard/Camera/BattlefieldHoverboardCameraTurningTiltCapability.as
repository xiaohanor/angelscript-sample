class UBattlefieldHoverboardCameraTurningTiltCapability : UHazePlayerCapability
{
	default CapabilityTags.Add(CameraTags::Camera);
	default CapabilityTags.Add(n"HoverboardCameraYawAxis");

	default DebugCategory = n"Hoverboard";

	default TickGroup = EHazeTickGroup::Gameplay;

	UBattlefieldHoverboardComponent HoverboardComp;
	UPlayerMovementComponent MoveComp;
	UCameraUserComponent CameraUser;
	UBattlefieldHoverboardLoopComponent LoopComp;
	UBattlefieldHoverboardGrindingComponent GrindComp;
	UBattlefieldHoverboardFreeFallingComponent FreeFallComp;

	UBattlefieldHoverboardCameraControlSettings CameraControlSettings;

	bool bIsDeactivating = false;

	const float TiltTurnBackDurationAtDeactivation = 0.5;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		HoverboardComp = UBattlefieldHoverboardComponent::Get(Player);
		
		LoopComp = UBattlefieldHoverboardLoopComponent::Get(Player);
		GrindComp = UBattlefieldHoverboardGrindingComponent::Get(Player);
		FreeFallComp = UBattlefieldHoverboardFreeFallingComponent::GetOrCreate(Player);
		
		CameraUser = UCameraUserComponent::Get(Player);

		MoveComp = UPlayerMovementComponent::Get(Player);

		CameraControlSettings = UBattlefieldHoverboardCameraControlSettings::GetSettings(Player);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if(LoopComp.bIsInLoop)
			return false;

		if(GrindComp.IsGrinding())
			return false;

		if(FreeFallComp.bIsFreeFalling)
			return false; 

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if(bIsDeactivating
		&& Math::IsNearlyEqual(HoverboardComp.AccCameraYawAxisTilt.Value, 0))
			return true;

		if(GrindComp.IsGrinding())
			return true;

		if(LoopComp.bIsInLoop)
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		Player.BlockCapabilities(CameraTags::CameraAlignWithWorldUp, this);
		bIsDeactivating = false;
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		Player.UnblockCapabilities(CameraTags::CameraAlignWithWorldUp, this);
		CameraUser.ClearYawAxis(this);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		// Yaw Axis should be synced by the camera system
		if(!HasControl())
			return;

		float CameraDeltaTime = Time::CameraDeltaSeconds;

		bIsDeactivating = CheckShouldDeactivate();
		
		if(bIsDeactivating)
		{
			HoverboardComp.AccCameraYawAxisTilt.AccelerateTo(0, TiltTurnBackDurationAtDeactivation, CameraDeltaTime);
		}
		else
		{
			FVector MovementInput = HoverboardComp.GetMovementInputWorldSpace();
			float TargetTurningTilt = -MovementInput.Y * CameraControlSettings.TurningTiltMax;
			HoverboardComp.AccCameraYawAxisTilt.AccelerateTo(TargetTurningTilt, CameraControlSettings.TurningTiltSpeed, CameraDeltaTime);
		}
		

		FVector WorldUp = Player.MovementWorldUp;
		FVector ForwardAlongGround = WorldUp.CrossProduct(-CameraUser.ViewRotation.RightVector);
		FVector SteeringYawAxis = WorldUp.RotateAngleAxis(HoverboardComp.AccCameraYawAxisTilt.Value, ForwardAlongGround);

		TEMPORAL_LOG(Player, "Hoverboard Camera Tilt")
			.Value("Turning Tilt", HoverboardComp.AccCameraYawAxisTilt.Value)
			.DirectionalArrow("Steering Yaw Axis", Player.ActorLocation, SteeringYawAxis * 500, 5, 40, FLinearColor::Blue)
		;

		CameraUser.SetYawAxis(SteeringYawAxis, this);
	}

	private bool CheckShouldDeactivate()
	{
		if(GrindComp.IsGrinding()
		&& GrindComp.CurrentGrindSplineComp.bDeactivateTurningTiltWhileGrinding)
			return true;

		if(FreeFallComp.bIsFreeFalling)
			return true; 

		return false;
	}
};