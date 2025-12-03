/**
 * Volume that allows a player using a focus camera to pan with the right stick.
 */
class AFocusCameraPanningVolume : APlayerTrigger
{
	UPROPERTY(DefaultComponent)
	UHazeRequestCapabilityOnPlayerComponent RequestComp;
	default RequestComp.InitialStoppedPlayerCapabilities.Add(n"CameraPanFocusCameraCapability");

	UPROPERTY(EditAnywhere, Category = "Camera Panning")
	float MaximumDistance = 500.0;
	UPROPERTY(EditAnywhere, Category = "Camera Panning")
	float InterpolationSpeed = 2.0;
	UPROPERTY(EditAnywhere, Category = "Camera Panning")
	float ReturnSpeed = 2.0;
	UPROPERTY(EditAnywhere, Category = "Camera Panning")
	float DelayBeforeReturn = 0.0;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		Super::BeginPlay();
		OnPlayerEnter.AddUFunction(this, n"OnPlayerEnter");
		OnPlayerLeave.AddUFunction(this, n"OnPlayerLeave");
	}

	UFUNCTION()
	private void OnPlayerEnter(AHazePlayerCharacter Player)
	{
		UCameraPanFocusCameraSettings::SetDelayBeforeReturn(Player, DelayBeforeReturn, this);
		UCameraPanFocusCameraSettings::SetInterpolationSpeed(Player, InterpolationSpeed, this);
		UCameraPanFocusCameraSettings::SetReturnSpeed(Player, ReturnSpeed, this);
		UCameraPanFocusCameraSettings::SetMaximumDistance(Player, MaximumDistance, this);
		RequestComp.StartInitialSheetsAndCapabilities(Player, this);
	}

	UFUNCTION()
	private void OnPlayerLeave(AHazePlayerCharacter Player)
	{
		RequestComp.StopInitialSheetsAndCapabilities(Player, this);
		UCameraPanFocusCameraSettings::ClearDelayBeforeReturn(Player, this);
		UCameraPanFocusCameraSettings::ClearInterpolationSpeed(Player, this);
		UCameraPanFocusCameraSettings::ClearReturnSpeed(Player, this);
		UCameraPanFocusCameraSettings::ClearMaximumDistance(Player, this);
	}
}