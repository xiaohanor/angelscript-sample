class ATeenDragonRollSettingsVolume : APlayerTrigger
{
	default bTriggerForMio = false;

	UPROPERTY(Category = "Settings", EditAnywhere)
	UTeenDragonRollSettings RollSettings;

	UPROPERTY(Category = "Settings", EditAnywhere)
	EHazeSettingsPriority Priority = EHazeSettingsPriority::Gameplay;

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
		Player.ApplySettings(RollSettings, this, Priority);
	}

	UFUNCTION()
	private void OnPlayerLeave(AHazePlayerCharacter Player)
	{
		Player.ClearSettingsByInstigator(this);
	}
}