class UBattlefieldHoverboardCameraTurningOffsetCapability : UHazePlayerCapability
{
	default CapabilityTags.Add(CameraTags::Camera);
	default CapabilityTags.Add(n"BattlefieldHoverboardCameraTurningOffset");

    default DebugCategory = n"Hoverboard";

	default TickGroup = EHazeTickGroup::Gameplay;

	UBattlefieldHoverboardComponent HoverboardComp;
	UPlayerMovementComponent MoveComp;
	UCameraUserComponent CameraUser;
	UBattlefieldHoverboardLoopComponent LoopComp;
	UBattlefieldHoverboardGrindingComponent GrindComp;
	UBattlefieldHoverboardFreeFallingComponent FreeFallComp;

	UBattlefieldHoverboardCameraControlSettings CameraControlSettings;

	FHazeAcceleratedVector AccTurningOffset;

	UCameraSettings PlayerCameraSettings;

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
		PlayerCameraSettings = UCameraSettings::GetSettings(Player);
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
		if(LoopComp.bIsInLoop)
			return true;

		if(GrindComp.IsGrinding())
			return true;

		if(FreeFallComp.bIsFreeFalling)
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		AccTurningOffset.SnapTo(PlayerCameraSettings.CameraOffset.Value);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		PlayerCameraSettings.CameraOffset.Clear(this, 0.5);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		float CameraDeltaTime = Time::CameraDeltaSeconds;

		FVector MovementInput = HoverboardComp.GetMovementInputWorldSpace();

		FVector TargetTurningOffset;
		TargetTurningOffset.X = Math::Abs(MovementInput.Y) * CameraControlSettings.MaxTurningOffset.X;
		TargetTurningOffset.Y = MovementInput.Y * CameraControlSettings.MaxTurningOffset.Y;

		AccTurningOffset.AccelerateTo(TargetTurningOffset, CameraControlSettings.TurningOffsetSpeed, CameraDeltaTime);
	
		PlayerCameraSettings.CameraOffset.ApplyAsAdditive(AccTurningOffset.Value, this);
	}
};