class UBattlefieldHoverboardGrindBalancingCameraTiltCapability : UHazePlayerCapability
{
	default CapabilityTags.Add(CameraTags::Camera);
	default CapabilityTags.Add(n"HoverboardCameraYawAxis");

	default DebugCategory = BattlefieldHoverboardDebugCategory::Hoverboard;

	default TickGroup = EHazeTickGroup::Gameplay;
	default TickGroupOrder = 110;

	UBattlefieldHoverboardComponent HoverboardComp;
	UPlayerMovementComponent MoveComp;
	UCameraUserComponent CameraUser;
	UBattlefieldHoverboardLoopComponent LoopComp;
	UBattlefieldHoverboardGrindingComponent GrindComp;

	UBattlefieldHoverboardGrindingSettings Settings;

	bool bIsDeactivating = false;

	const float TiltTurnBackDurationAtDeactivation = 0.5;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		HoverboardComp = UBattlefieldHoverboardComponent::Get(Player);
		
		LoopComp = UBattlefieldHoverboardLoopComponent::Get(Player);
		GrindComp = UBattlefieldHoverboardGrindingComponent::Get(Player);
		
		CameraUser = UCameraUserComponent::Get(Player);

		Settings = UBattlefieldHoverboardGrindingSettings::GetSettings(Player);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if(!GrindComp.bIsOnGrind)
			return false;

		if(GrindComp.CurrentGrindSplineComp.bDeactivateTurningTiltWhileGrinding)
			return false;

		if(!GrindComp.CurrentGrindSplineComp.bEnableBalancingWhileOnGrind)
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if(bIsDeactivating
		&& Math::IsNearlyEqual(HoverboardComp.AccCameraYawAxisTilt.Value, 0))
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
		float CameraDeltaTime = Time::CameraDeltaSeconds;

		bIsDeactivating = CheckShouldDeactivate();
		
		if(bIsDeactivating)
		{
			HoverboardComp.AccCameraYawAxisTilt.AccelerateTo(0, TiltTurnBackDurationAtDeactivation, CameraDeltaTime);
		}
		else
		{
			float TargetTurningTilt = -GrindComp.GrindBalance * Settings.BalanceMaxCameraTilt;
			HoverboardComp.AccCameraYawAxisTilt.AccelerateTo(TargetTurningTilt, Settings.BalanceCameraTiltDuration, CameraDeltaTime);
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
		if(!GrindComp.bIsOnGrind
		|| GrindComp.CurrentGrindSplineComp.bDeactivateTurningTiltWhileGrinding
		|| !GrindComp.CurrentGrindSplineComp.bEnableBalancingWhileOnGrind)
			return true; 

		return false;
	}
};