class AMoonMarketWaterBubbleManager : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

#if EDITOR
	UPROPERTY(DefaultComponent, Attach = Root)
	UBillboardComponent Visual;
	default Visual.SetWorldScale3D(FVector(5.0));
#endif

	UPROPERTY(DefaultComponent)
	UHazeListedActorComponent ListedComp;
	default ListedComp.bDelistWhileActorDisabled = false;

	UPROPERTY(DefaultComponent)
	UMoonMarketCatProgressComponent CatProgressComp;

	UPROPERTY(EditInstanceOnly)
	AMoonMarketCat GardenCat;

	TArray<AMoonMarketWaterBubble> Bubbles;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		Bubbles = TListedActors<AMoonMarketWaterBubble>().GetArray();
		for (AMoonMarketWaterBubble Bubble : Bubbles)
		{
			Bubble.AddActorDisable(this);
		}
		GardenCat.OnMoonCatSoulCaught.AddUFunction(this, n"OnMoonCatSoulCaught");
		CatProgressComp.OnProgressionActivated.AddUFunction(this, n"OnProgressionActivated");
	}

	UFUNCTION()
	private void OnProgressionActivated()
	{
		for (AMoonMarketWaterBubble Bubble : Bubbles)
		{
			Bubble.RemoveActorDisable(this);
		}
	}

	UFUNCTION()
	private void OnMoonCatSoulCaught(AHazePlayerCharacter Player, AMoonMarketCat Cat)
	{
		for (AMoonMarketWaterBubble Bubble : Bubbles)
		{
			Bubble.RemoveActorDisable(this);
		}
	}

#if EDITOR
	UFUNCTION(DevFunction)
	void EnableAllBubbles()
	{
		for (AMoonMarketWaterBubble Bubble : Bubbles)
		{
			Bubble.RemoveActorDisable(this);
		}
	}
#endif
};