class ASummitEggChaseKillVolume : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(EditInstanceOnly)
	APlayerTrigger PlayerTrigger;

	UPROPERTY()
	bool bIsActive;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		PlayerTrigger.OnPlayerEnter.AddUFunction(this, n"OnOverlap");
	}

	UFUNCTION()
	void OnOverlap(AHazePlayerCharacter Player)
	{
		if (!bIsActive)
			return;

		Player.DamagePlayerHealth(1);
	}

	UFUNCTION()
	void ActivateEggKillVolume()
	{
		bIsActive = true;
	}

};