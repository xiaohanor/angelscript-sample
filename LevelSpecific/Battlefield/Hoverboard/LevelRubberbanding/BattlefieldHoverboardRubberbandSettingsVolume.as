class ABattlefieldHoverboardRubberbandSettingsVolume : APlayerTrigger
{
	default SetBrushColor(FLinearColor::Green);
	default BrushComponent.LineThickness = 5.0;

	UPROPERTY(EditAnywhere, Category = "Settings")
	UBattlefieldHoverboardLevelRubberbandingSettings RubberbandSettings;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		Super::BeginPlay();
		OnPlayerEnter.AddUFunction(this, n"PlayerEntered");
		OnPlayerLeave.AddUFunction(this, n"OnPlayerLeave");
	}

	UFUNCTION()
	private void OnPlayerLeave(AHazePlayerCharacter Player)
	{
		Player.ClearSettingsByInstigator(this);
	}

	UFUNCTION(NotBlueprintCallable)
	private void PlayerEntered(AHazePlayerCharacter Player)
	{
		Player.ApplySettings(RubberbandSettings, this);
	}
};