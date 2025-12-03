class ALaserShaftCameraPitchTrigger : APlayerTrigger
{
	default bTriggerForMio = false;

	// UPROPERTY(EditAnywhere)
	// FHazeCameraClampSettings ClampSettings;

	UPROPERTY(EditAnywhere)
	float TargetPitch = 70.0;

	bool bPlayerInTrigger = false;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		Super::BeginPlay();
		OnPlayerEnter.AddUFunction(this, n"PlayerEnter");
		OnPlayerLeave.AddUFunction(this, n"PlayerLeave");
	}

	UFUNCTION()
	private void PlayerEnter(AHazePlayerCharacter Player)
	{
		if (bPlayerInTrigger)
			return;

		bPlayerInTrigger = true;

		FHazeCameraClampSettings ClampSettings;
		ClampSettings.ApplyClampsPitch(-TargetPitch, TargetPitch);
		UCameraSettings::GetSettings(Game::Zoe).Clamps.Apply(ClampSettings, this, 2, EHazeCameraPriority::High);
	}

	UFUNCTION()
	private void PlayerLeave(AHazePlayerCharacter Player)
	{
		if (!bPlayerInTrigger)
			return;

		bPlayerInTrigger = false;

		UCameraSettings::GetSettings(Game::Zoe).Clamps.Clear(this);
	}
}