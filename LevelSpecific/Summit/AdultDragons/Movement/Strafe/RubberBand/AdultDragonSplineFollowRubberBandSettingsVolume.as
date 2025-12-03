
class AAdultDragonSplineFollowRubberBandingSettingsVolume : APlayerTrigger
{
	default SetBrushColor(FLinearColor::Purple);
	default BrushComponent.LineThickness = 5.0;

	UPROPERTY(EditAnywhere)
	UAdultDragonSplineFollowRubberBandingSettings RubberBandSettings;

	UPROPERTY(EditAnywhere)
	EHazeSettingsPriority Priority = EHazeSettingsPriority::Gameplay;

	UPROPERTY(EditAnywhere)
	bool bSettingsPersistAfterExit = false;

	bool bDoOnce;

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
		if (bDoOnce)
			return;

		bDoOnce = true;

		for(auto CurrentPlayer : Game::GetPlayers())
		{
			CurrentPlayer.ClearSettingsOfClass(UAdultDragonSplineFollowRubberBandingSettings, CurrentPlayer);
			CurrentPlayer.ApplySettings(RubberBandSettings, CurrentPlayer, Priority);
		}
	}

	UFUNCTION()
	private void OnPlayerLeave(AHazePlayerCharacter Player)
	{
		if (!bSettingsPersistAfterExit)
		{
			for(auto CurrentPlayer : Game::GetPlayers())
			{
				CurrentPlayer.ClearSettingsOfClass(UAdultDragonSplineFollowRubberBandingSettings, CurrentPlayer);
			}
		}
	}
}