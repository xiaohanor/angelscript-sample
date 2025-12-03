class ASanctuaryBossSlideSettings : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(EditAnywhere)
	APlayerTrigger EnterTrigger;

	UPROPERTY(EditAnywhere)
	APlayerTrigger ExitTrigger;

	

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		EnterTrigger.OnPlayerEnter.AddUFunction(this, n"HandleOnPlayerEnter");
		ExitTrigger.OnPlayerEnter.AddUFunction(this, n"HandleOnPlayerExit");
	}

	UFUNCTION(BlueprintOverride)
	void EndPlay(EEndPlayReason EndPlayReason)
	{
		for (auto Player : Game::Players)
			UMovementStandardSettings::ClearWalkableSlopeAngle(Player, this, EHazeSettingsPriority::Gameplay);
	}

	UFUNCTION()
	private void HandleOnPlayerExit(AHazePlayerCharacter Player)
	{
		UMovementStandardSettings::ClearWalkableSlopeAngle(Player, this, EHazeSettingsPriority::Gameplay);
	}

	UFUNCTION()
	private void HandleOnPlayerEnter(AHazePlayerCharacter Player)
	{
		UMovementStandardSettings::SetWalkableSlopeAngle(Player, 85.0, this, EHazeSettingsPriority::Gameplay);
	}
};