class ASolarFlareSwingWeightManager : APlayerTrigger
{
// #if EDITOR
// 	UPROPERTY(DefaultComponent, Attach = Root)
// 	UBillboardComponent Visual;
// 	default Visual.SetWorldScale3D(FVector(5.0));
// #endif

	UPROPERTY(EditAnywhere)
	TArray<ASwingPoint> SwingPoints;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		Super::BeginPlay();

		OnPlayerEnter.AddUFunction(this, n"SwingOnPlayerEnter");
		OnPlayerLeave.AddUFunction(this, n"SwingOnPlayerLeave");

		for (AHazePlayerCharacter Player : Game::Players)
		{
			for (ASwingPoint Swing : SwingPoints)
			{
				Swing.SwingPointComp.DisableForPlayer(Player, this);
			}
		}
	}

	UFUNCTION()
	private void SwingOnPlayerEnter(AHazePlayerCharacter Player)
	{
		SetSwingsAvailableFor(Player, true);
	}

	UFUNCTION()
	private void SwingOnPlayerLeave(AHazePlayerCharacter Player)
	{
		SetSwingsAvailableFor(Player, false);
	}

	void SetSwingsAvailableFor(AHazePlayerCharacter Player, bool bIsAvail)
	{
		if (bIsAvail)
		{
			for (ASwingPoint Swing : SwingPoints)
			{
				Swing.SwingPointComp.EnableForPlayer(Player, this);
			}
		}
		else
		{
			for (ASwingPoint Swing : SwingPoints)
			{
				Swing.SwingPointComp.DisableForPlayer(Player, this);
			}			
		}
	}
};