event void FOnAnyMoonMarketPumpkinLauncherUsed();

class AMoonMarketPumpkinGraveyardManager : AHazeActor
{
	UPROPERTY()
	FOnAnyMoonMarketPumpkinLauncherUsed OnAnyMoonMarketPumpkinLauncherUsed;

	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

#if EDITOR
	UPROPERTY(DefaultComponent, Attach = Root)
	UBillboardComponent Visual;
	default Visual.SetWorldScale3D(FVector(6));
#endif

	UPROPERTY(DefaultComponent)
	UMoonMarketCatProgressComponent ProgressComp;

	UPROPERTY(EditInstanceOnly)
	TArray<AMoonMarketPumpkinLauncher> PumpkinLaunchers;

	UPROPERTY(EditInstanceOnly)
	AMoonMarketCat Cat;

	UPROPERTY(EditInstanceOnly)
	APlayerTrigger PlayerTrigger;

	bool bGraveyardCompleted;

	bool bHaveActivatedPumpkins;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		Cat.OnMoonCatSoulCaught.AddUFunction(this, n"OnMoonCatSoulCaught");
		PlayerTrigger.OnPlayerEnter.AddUFunction(this, n"OnPlayerEnter");
		ProgressComp.OnProgressionActivated.AddUFunction(this, n"OnProgressionActivated");
	}

	UFUNCTION()
	private void OnProgressionActivated()
	{
		for (AMoonMarketPumpkinLauncher Pumpkin : PumpkinLaunchers)
		{
			Pumpkin.GraveyardPumpkinAppear();
			Pumpkin.OnMoonMarketPumpkinLauncherUsed.AddUFunction(this, n"OnMoonMarketPumpkinLauncherUsed");
		}

		bHaveActivatedPumpkins = true;
	}

	UFUNCTION()
	private void OnMoonMarketPumpkinLauncherUsed()
	{
		OnAnyMoonMarketPumpkinLauncherUsed.Broadcast();
	}

	UFUNCTION()
	private void OnPlayerEnter(AHazePlayerCharacter Player)
	{
		if (!bGraveyardCompleted)
			return;

		if (bHaveActivatedPumpkins)
			return;
		
		for (AMoonMarketPumpkinLauncher Pumpkin : PumpkinLaunchers)
			Pumpkin.GraveyardPumpkinAppear();

		bHaveActivatedPumpkins = true;
	}

	UFUNCTION()
	private void OnMoonCatSoulCaught(AHazePlayerCharacter Player, AMoonMarketCat CurrentCat)
	{
		bGraveyardCompleted = true;
	}
};