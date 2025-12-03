class UPlayerTailTeenDragonComponent : UPlayerTeenDragonComponent
{
	TArray<FInstigator> ClimbingInstigators;
	bool bValidJumpTarget;
	FVector JumpTargetPos;

	int CurrentAttackComboIndex = -1;

	UPROPERTY(Category = "UI")
	TSubclassOf<UCrosshairWidget> AttackCrosshair;

	UPROPERTY(Category = "Settings")
	UHazeCameraSettingsDataAsset ClimbCameraSettings;

	UPROPERTY(Category = "Settings")
	UHazeCameraSettingsDataAsset RollCameraSettings;
	
	UPROPERTY(Category = "Camera Shake")
	TSubclassOf<UCameraShakeBase> TailAttackCameraShake;

	UPROPERTY(Category = "Camera Shake")
	TSubclassOf<UCameraShakeBase> RollAreaAttackCameraShake;

	UPROPERTY(Category = "Camera Shake")
	TSubclassOf<UCameraShakeBase> RollingLandCameraShake;

	UPROPERTY(Category = "Camera Shake")
	TSubclassOf<UCameraShakeBase> RollContinuousCameraShake;

	UPROPERTY(Category = "Camera Shake")
	TSubclassOf<UCameraShakeBase> GroundPoundAttackDiveCameraShake;

	UPROPERTY(Category = "Camera Shake")
	TSubclassOf<UCameraShakeBase> GroundPoundAttackLandCameraShake;

	UPROPERTY(Category = "Settings")
	UTeenDragonRollSettings RollSettings;

	UPROPERTY()
	float RollingLandCameraLagDuration;
	
	UPROPERTY()
	float RollingLandCameraLagDistance;

	bool bSimplifiedRollingWheelOnRailInput = true;
	bool bRampClimbEnterMode = true;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		SetupGeckoClimbAngleDownInput();
		SetupGeckoClimbAngleUpInput();
		SetupRampClimbEnterModeToggleInput();
		SetupSimplifiedRollingWheelOnRailInput();
		SetupUnSimplifiedRollingWheelOnRailInput();
	}

	FTransform GetTailStartTransform() const property
	{
		FTransform SocketTransform = TeenDragon.Mesh.GetSocketTransform(n"Tail9");
		return SocketTransform;
	}
	
	bool IsClimbing() const
	{
		return ClimbingInstigators.Num() > 0;
	}
	
	void SetupGeckoClimbAngleUpInput()
	{
		FHazeDevInputInfo Info;

		Info.Name = n"Increase Gecko Climb Camera Angle";
		Info.Category = n"Dragon";
		Info.OnTriggered.BindUFunction(this, n"IncreaseGeckoClimbAngle");

		Info.AddKey(EKeys::Gamepad_RightShoulder);
		Info.AddKey(EKeys::P);

		Game::Zoe.RegisterDevInput(Info);
	}

	void SetupGeckoClimbAngleDownInput()
	{
		FHazeDevInputInfo Info;

		Info.Name = n"Reduce Gecko Climb Camera Angle";
		Info.Category = n"Dragon";
		Info.OnTriggered.BindUFunction(this, n"ReduceGeckoClimbAngle");

		Info.AddKey(EKeys::Gamepad_LeftShoulder);
		Info.AddKey(EKeys::O);

		Game::Zoe.RegisterDevInput(Info);
	}

	void SetupRampClimbEnterModeToggleInput()
	{
		FHazeDevInputInfo Info;

		Info.Name = n"Toggle Ramp Enter Mode";
		Info.Category = n"Dragon";
		Info.OnTriggered.BindUFunction(this, n"ToggleRampEnterMode");

		Info.AddKey(EKeys::Gamepad_FaceButton_Bottom);
		Info.AddKey(EKeys::Y);

		Game::Zoe.RegisterDevInput(Info);
	}

	void SetupSimplifiedRollingWheelOnRailInput()
	{
		FHazeDevInputInfo Info;

		Info.Name = n"Set simplified hauling room input";
		Info.Category = n"Dragon";
		Info.OnTriggered.BindUFunction(this, n"ToggleSimplifiedRollingWheelOnRailInput");

		Info.AddKey(EKeys::Gamepad_FaceButton_Top);
		Info.AddKey(EKeys::H);

		Game::Zoe.RegisterDevInput(Info);
	}
	
	void SetupUnSimplifiedRollingWheelOnRailInput()
	{
		FHazeDevInputInfo Info;

		Info.Name = n"Set unsimplified hauling room input";
		Info.Category = n"Dragon";
		Info.OnTriggered.BindUFunction(this, n"ToggleUnSimplifiedRollingWheelOnRailInput");

		Info.AddKey(EKeys::Gamepad_FaceButton_Right);
		Info.AddKey(EKeys::G);

		Game::Zoe.RegisterDevInput(Info);
	}

	UFUNCTION()
	private void ToggleSimplifiedRollingWheelOnRailInput()
	{
		bSimplifiedRollingWheelOnRailInput = true;
		Print("Hauling room input is now: LEFT -> RIGHT on stick", 5.0, FLinearColor::Green);
	}

	UFUNCTION()
	private void ToggleUnSimplifiedRollingWheelOnRailInput()
	{
		bSimplifiedRollingWheelOnRailInput = false;
		Print("Hauling room input is now: IN DIRECTION OF STICK", 5.0, FLinearColor::Green);
	}


	UFUNCTION()
	void IncreaseGeckoClimbAngle()
	{
		auto Settings = UTeenDragonTailGeckoClimbSettings::GetSettings(PlayerOwner);
		Settings.CameraRollMultiplier += 0.25;
		Settings.CameraRollMultiplier = Math::Clamp(Settings.CameraRollMultiplier, 0, 1);
		Print(f"Climb camera angle is now: {Settings.CameraRollMultiplier * 90}", 2.0);
	}

	UFUNCTION()
	void ReduceGeckoClimbAngle()
	{
		auto Settings = UTeenDragonTailGeckoClimbSettings::GetSettings(PlayerOwner);
		Settings.CameraRollMultiplier -= 0.25;
		Settings.CameraRollMultiplier = Math::Clamp(Settings.CameraRollMultiplier, 0, 1);
		Print(f"Climb camera angle is now: {Settings.CameraRollMultiplier * 90}", 2.0);
	}

	UFUNCTION()
	void ToggleRampEnterMode()
	{
		bRampClimbEnterMode = !bRampClimbEnterMode;
		
		Print(f"Ramp enter mode is now: {bRampClimbEnterMode}", 2.0);
	}
}