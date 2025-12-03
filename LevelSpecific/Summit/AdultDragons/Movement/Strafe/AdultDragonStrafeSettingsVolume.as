class AAdultDragonStrafeSettingsVolume : APlayerTrigger
{
	default SetBrushColor(FLinearColor::Green);
	default BrushComponent.LineThickness = 5.0;

	UPROPERTY(EditAnywhere)
	UAdultDragonStrafeSettings StrafeSettings;

	UPROPERTY(EditAnywhere)
	float BlendInTime = 3.0;

	UPROPERTY(EditAnywhere)
	float BlendOutTime = 1.0;

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
		Player.ApplySettings(StrafeSettings, this);
	}

	UFUNCTION()
	private void OnPlayerLeave(AHazePlayerCharacter Player)
	{
		Player.ClearSettingsByInstigator(this);
	}
};