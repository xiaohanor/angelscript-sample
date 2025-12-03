class URemoteHackableCameraCapability : URemoteHackableBaseCapability
{
	URemoteHackingPlayerComponent HackingPlayerComp;

	ARemoteHackableCameraConsole Console;
	ARemoteHackableCamera CurrentCamera;
	TArray<ARemoteHackableCamera> Cameras;
	int CameraIndex = 0;

	float RotateSpeed = 15.0;

	FHazeAcceleratedVector2D AccInput;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Super::Setup();

		Console = Cast<ARemoteHackableCameraConsole>(Owner);
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		Super::OnActivated();

		HackingPlayerComp = URemoteHackingPlayerComponent::Get(Player);
		HackingPlayerComp.TriggerPostProcessTransition();

		AccInput.SnapTo(FVector2D::ZeroVector);

		CameraIndex = 0;
		Cameras = Console.Cameras;
		CurrentCamera = Cameras[0];
		Player.ActivateCamera(CurrentCamera.CameraComp, 0.0, this, EHazeCameraPriority::High);

		UCameraSettings::GetSettings(Player).FOV.Apply(70.0, this, 0.0, EHazeCameraPriority::High);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		Super::OnDeactivated();

		HackingPlayerComp.TriggerPostProcessTransition();
		Player.DeactivateCamera(CurrentCamera.CameraComp);

		FRotator CameraExitRot = Console.ActorRotation;
		CameraExitRot.Pitch = -15.0;
		CameraExitRot.Yaw += 180.0;
		Player.SnapCameraAtEndOfFrame(CameraExitRot, SnapType = EHazeCameraSnapType::World);

		UCameraSettings::GetSettings(Player).FOV.Clear(this, 0.0);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		Super::TickActive(DeltaTime);

		if (WasActionStarted(ActionNames::PrimaryLevelAbility))
			SwapCamera();

		FVector2D MoveInput = GetAttributeVector2D(AttributeVectorNames::LeftStickRaw);
		FVector2D CameraInput = GetAttributeVector2D(AttributeVectorNames::RightStickRaw);
	
		FVector2D TotalInput = MoveInput + CameraInput;
		TotalInput.X = Math::Clamp(TotalInput.X, -1.0, 1.0);
		TotalInput.Y = Math::Clamp(TotalInput.Y, -1.0, 1.0);

		AccInput.AccelerateTo(TotalInput, 1.0, DeltaTime);

		CurrentCamera.CurrentPitch = Math::Clamp(CurrentCamera.CurrentPitch + (AccInput.Value.Y * RotateSpeed * DeltaTime), CurrentCamera.PitchRange.X, CurrentCamera.PitchRange.Y);
		CurrentCamera.CurrentYaw = Math::Clamp(CurrentCamera.CurrentYaw + (AccInput.Value.X * RotateSpeed * DeltaTime), CurrentCamera.YawRange.X, CurrentCamera.YawRange.Y);
	}

	void SwapCamera()
	{
		CameraIndex++;
		if (CameraIndex >= Cameras.Num())
			CameraIndex = 0;

		HackingPlayerComp.TriggerPostProcessTransition();
		Player.DeactivateCamera(CurrentCamera.CameraComp);
		CurrentCamera = Cameras[CameraIndex];
		Player.ActivateCamera(CurrentCamera.CameraComp, .0, this, EHazeCameraPriority::High);
	}
}