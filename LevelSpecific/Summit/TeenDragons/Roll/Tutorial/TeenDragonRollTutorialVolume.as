class ATeenDragonRollTutorialVolume : ATutorialVolume
{
	default VolumeType = ETutorialVolumeType::UseTutorialCapability;

	UPROPERTY(EditInstanceOnly)
	TArray<ASummitNightQueenGem> Crystals;

	UPROPERTY(EditDefaultsOnly)
	float MaxDuration = 4.0;
	float CurrentDuration;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		Super::BeginPlay();
		OnPlayerEnter.AddUFunction(this, n"OnTailDragonEnter");
		OnPlayerLeave.AddUFunction(this, n"OnTailDragonExit");
		SetActorTickEnabled(false);
	}

	UFUNCTION()
	private void OnTailDragonEnter(AHazePlayerCharacter Player)
	{
		if (Player.IsZoe())
			SetActorTickEnabled(true);
	}

	UFUNCTION()
	private void OnTailDragonExit(AHazePlayerCharacter Player)
	{
		if (Player.IsZoe())
			SetActorTickEnabled(false);
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		CurrentDuration += DeltaSeconds;
	}

	//True if no crystals have been destroyed, and if the current duration is more than the max duration
	bool ShouldUsePrompt() const
	{
		for (ASummitNightQueenGem Crystal : Crystals)
		{
			if (Crystal.bCrystalDestroyed)
				return false;
		}

		return CurrentDuration > MaxDuration;
	}
};