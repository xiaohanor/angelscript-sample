class ACatCollectionArea : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent)
	UBoxComponent BoxComp;
	default BoxComp.SetCollisionResponseToAllChannels(ECollisionResponse::ECR_Ignore);
	default BoxComp.SetCollisionResponseToChannel(ECollisionChannel::ECC_Visibility, ECollisionResponse::ECR_Overlap);

	UPROPERTY(EditInstanceOnly)
	AHazeCameraActor Camera;

	UPROPERTY(EditInstanceOnly)
	AMoonMarketSoulCollectionGate GateToOpen;

	UPROPERTY(EditInstanceOnly)
	TArray<AMoonGateCatHead> CatHeads;

	int MaxNum;
	int CurrentNum;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		BoxComp.OnComponentBeginOverlap.AddUFunction(this, n"OnComponentBeginOverlap");
		MaxNum = CatHeads.Num();
	}

	UFUNCTION()
	private void OnComponentBeginOverlap(UPrimitiveComponent OverlappedComponent, AActor OtherActor,
	                                     UPrimitiveComponent OtherComp, int OtherBodyIndex,
	                                     bool bFromSweep, const FHitResult&in SweepResult)
	{
		if (CatHeads.Num() == 0)
			return;

		AMoonMarketCat Cat = Cast<AMoonMarketCat>(OtherActor);
		if (Cat == nullptr)
			return;

		Cat.StartSoulDeliverance();
		Cat.OnMoonCatFinishDelivering.AddUFunction(this, n"OnMoonCatFinishDelivering");
		Cat.SoulTargetPlayer.ActivateCamera(Camera, 2.0, this);
	}

	UFUNCTION()
	private void OnMoonCatFinishDelivering(AHazePlayerCharacter Player, AMoonMarketCat Cat)
	{
		Player.DeactivateCameraByInstigator(this, 2.0);
		if (CurrentNum >= MaxNum)
		{
			Timer::SetTimer(GateToOpen, n"ActivateGate", 1.25, false);
		}

		CatHeads.RemoveAt(0);
		CurrentNum++;
	}

	UFUNCTION()
	void DelayedActivateGate()
	{
		
	}
};