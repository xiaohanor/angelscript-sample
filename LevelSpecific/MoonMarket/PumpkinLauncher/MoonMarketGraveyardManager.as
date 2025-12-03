class AMoonMarketGraveyardManager : AHazeActor
{
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
	ARespawnPointVolume StartRespawnVol;
	UPROPERTY(EditInstanceOnly)
	ARespawnPointVolume CompletedRespawnVol;

	UPROPERTY(EditInstanceOnly)
	ARespawnPointVolume StartRespawnVolMainland;
	UPROPERTY(EditInstanceOnly)
	ARespawnPointVolume CompletedRespawnVolMainland;

	UPROPERTY(EditInstanceOnly)
	AMoonMarketCat Cat;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		Cat.OnMoonCatSoulCaught.AddUFunction(this, n"OnMoonCatSoulCaught");
		ProgressComp.OnProgressionActivated.AddUFunction(this, n"OnProgressionActivated");
		CompletedRespawnVol.DisableRespawnPointVolume(this);
		CompletedRespawnVolMainland.DisableRespawnPointVolume(this);
	}

	UFUNCTION()
	private void OnProgressionActivated()
	{
		// CompletedRespawnVol.EnableRespawnPointVolume(this);
		// CompletedRespawnVolMainland.EnableRespawnPointVolume(this);
		// StartRespawnVol.DisableRespawnPointVolume(this);
		// StartRespawnVolMainland.DisableRespawnPointVolume(this);
	}

	UFUNCTION()
	private void OnMoonCatSoulCaught(AHazePlayerCharacter Player, AMoonMarketCat CurrentCat)
	{
		// CompletedRespawnVol.EnableRespawnPointVolume(this);
		// CompletedRespawnVolMainland.EnableRespawnPointVolume(this);
		// StartRespawnVol.DisableRespawnPointVolume(this);
		// StartRespawnVolMainland.DisableRespawnPointVolume(this);
	}
};