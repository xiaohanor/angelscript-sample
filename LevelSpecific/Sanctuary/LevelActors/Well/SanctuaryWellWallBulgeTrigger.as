class ASanctuaryWellWallBulgeTrigger : APlayerTrigger
{
	UPROPERTY(EditInstanceOnly)
	ASanctuaryWellBrokenWall BulgingWall;

	bool bActivated = false;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		Super::BeginPlay();
		
		OnPlayerEnter.AddUFunction(this, n"HandlePlayerEnter");
	}

	UFUNCTION()
	private void HandlePlayerEnter(AHazePlayerCharacter Player)
	{
		if (bActivated)
			return;

		bActivated = true;

		BulgingWall.Bulge();
	}
};