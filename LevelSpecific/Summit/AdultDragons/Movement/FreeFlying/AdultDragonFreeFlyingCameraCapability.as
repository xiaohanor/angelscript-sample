class UAdultDragonFreeFlyingCameraCapability : UHazePlayerCapability
{
	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;

	default CapabilityTags.Add(n"AdultDragon");
	default CapabilityTags.Add(CameraTags::Camera);
	default CapabilityTags.Add(CameraTags::CameraControl);

	default CapabilityTags.Add(CapabilityTags::Input);
	default CapabilityTags.Add(CapabilityTags::StickInput);

	default DebugCategory = n"AdultDragon";
	default TickGroup = EHazeTickGroup::BeforeMovement;
	default TickGroupOrder = 1;

	UPlayerAdultDragonComponent DragonComp;
	UAdultDragonFreeFlyingComponent FreeFlyingComp;
	UAdultDragonAirDriftingComponent DriftComp;
	UPlayerMovementComponent MoveComp;
	UAdultDragonFreeFlightSettings FlightSettings;
	UAdultDragonInputCameraSettings InputCameraSettings;

	UCameraUserComponent CameraUser;
	FHazeAcceleratedVector AccTurningOffset;
	FHazeAcceleratedRotator AccWantedRotation;
	FHazeAcceleratedRotator AccInputRotation;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		FlightSettings = UAdultDragonFreeFlightSettings::GetSettings(Player);
		InputCameraSettings = UAdultDragonInputCameraSettings::GetSettings(Player);

		CameraUser = UCameraUserComponent::Get(Player);
		DragonComp = UPlayerAdultDragonComponent::Get(Player);
		DriftComp = UAdultDragonAirDriftingComponent::Get(Player);
		MoveComp = UPlayerMovementComponent::Get(Player);
		FreeFlyingComp = UAdultDragonFreeFlyingComponent::Get(Player);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (FreeFlyingComp == nullptr)
			return false;

		if (!CameraUser.CanControlCamera())
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (!CameraUser.CanControlCamera())
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		float BlendTime = 0;
		if (DragonComp.FlightMode != EAdultDragonFlightMode::NotStarted)
			BlendTime = FlightSettings.CameraBlendInTime;
		
		Player.ApplyCameraSettings(FreeFlyingComp.CameraSettings, BlendTime, this, SubPriority = 60);

		AccWantedRotation.SnapTo(CameraUser.GetDesiredRotation());
		AccTurningOffset.SnapTo(FVector::ZeroVector);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		Player.ClearCameraSettingsByInstigator(this, FlightSettings.CameraBlendOutTime);
		// SpeedEffect::ClearSpeedEffect(Player, this);
		Player.StopCameraShakeByInstigator(this);
	}

	UFUNCTION(BlueprintOverride)
	void PreTick(float DeltaTime)
	{
		if (FreeFlyingComp == nullptr)
			FreeFlyingComp = UAdultDragonFreeFlyingComponent::Get(Player);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if (HasControl())
		{
			const float UndilatedDeltaTime = Time::CameraDeltaSeconds;
			UpdateInputRotation(UndilatedDeltaTime);
			UpdateWantedRotation(UndilatedDeltaTime);
			ApplyTurningOffset(UndilatedDeltaTime);

			if (CameraUser.CanApplyUserInput())
			{
				FRotator FinalizedDeltaRotation = AccWantedRotation.Value - Player.ViewRotation;

				if (DragonComp.bRightStickCameraIsOn)
					FinalizedDeltaRotation += AccInputRotation.Value;

				CameraUser.AddUserInputDeltaRotation(FinalizedDeltaRotation, this);
			}
		}
	}

	void UpdateInputRotation(float DeltaTime)
	{
		FVector2D CameraInput = Player.GetCameraInput();
		FRotator WantedInputRotation = FRotator(CameraInput.Y * InputCameraSettings.InputCameraMaxPitch,
												CameraInput.X * InputCameraSettings.InputCameraMaxYaw,
												0);

		AccInputRotation.AccelerateTo(WantedInputRotation, InputCameraSettings.InputCameraRotationDuration, DeltaTime);
	}

	void UpdateWantedRotation(float DeltaTime)
	{
		AccWantedRotation.AccelerateTo(DragonComp.WantedRotation, FlightSettings.CameraAcceleration, DeltaTime);
	}

	void ApplyTurningOffset(float DeltaTime)
	{
		FVector MovementInput;
		if (HasControl())
			MovementInput = MoveComp.MovementInput;
		else
			MovementInput = MoveComp.GetSyncedMovementInputForAnimationOnly();

		FVector OffsetMax = FVector(FlightSettings.ForwardTurningCameraOffsetMax, FlightSettings.RightTurningCameraOffsetMax, FlightSettings.UpTurningCameraOffsetMax);
		FVector TurningOffset = FVector(Math::Abs(MovementInput.Y), MovementInput.Y, MovementInput.X) * OffsetMax;

		AccTurningOffset.AccelerateTo(TurningOffset, FlightSettings.TurningOffsetSpeed, DeltaTime);
		UCameraSettings::GetSettings(Player).CameraOffset.ApplyAsAdditive(AccTurningOffset.Value, this);
	}
};