class UAdultDragonTurnBackComponent : UActorComponent
{
	AHazePlayerCharacter Player;

	UHazeCameraUserComponent PlayerCameraUser;

	UPROPERTY(EditDefaultsOnly, Category = "Settings")
	TSubclassOf<AStaticCameraActor> StoppedCameraClass;
	AStaticCameraActor StoppedCamera;

	UPROPERTY(EditDefaultsOnly, Category = "Settings")
	UHazeCameraSettingsDataAsset TurnBackCameraSettings;

	UPROPERTY(EditDefaultsOnly, Category = "Settings")
	UAdultDragonTurnBackSettings Settings;

	FVector CameraWorldLocation;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		Player = Cast<AHazePlayerCharacter>(Owner);

		PlayerCameraUser = UHazeCameraUserComponent::Get(Player);

		auto NewCamera = SpawnActor(StoppedCameraClass, PlayerCameraUser.ViewLocation, PlayerCameraUser.ViewRotation);

		StoppedCamera = Cast<AStaticCameraActor>(NewCamera);

		Player.ApplyDefaultSettings(Settings);
	}

	// UFUNCTION(BlueprintOverride)
	// void Tick(float DeltaSeconds)
	// {
		// TEMPORAL_LOG(this)
		// .Sphere("Stopped Camera Location",StoppedCamera.Camera.GetViewLocation(PlayerCameraUser), 50, FLinearColor::Red)
		// .Sphere("Dragon Camera", Cast<APlayerCharacter>(Player).Camera.GetViewLocation(PlayerCameraUser), 50, FLinearColor::Blue);

		// Player.CameraOffsetComponent.FreezeRotationAndLerpBackToParent(this, 10);

	// }

	void BlendToStoppedCamera(UHazeCapability Instigator, float BlendTime)
	{
		StoppedCamera.ActorLocation = PlayerCameraUser.ViewLocation;
		StoppedCamera.ActorRotation = PlayerCameraUser.ViewRotation;
		Player.ActivateCamera(StoppedCamera, BlendTime, this);

		Player.ApplyCameraSettings(TurnBackCameraSettings, BlendTime, Instigator, SubPriority = 60);
	}

	void BlendBackCamera(UHazeCapability Instigator, float BlendTime)
	{
		Player.DeactivateCamera(StoppedCamera, BlendTime);

		Player.ClearCameraSettingsByInstigator(Instigator, BlendTime);
	}
};