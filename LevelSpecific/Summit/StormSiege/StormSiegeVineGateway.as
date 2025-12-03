class AStormSiegeVineGateway : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	USceneComponent VineRoot1;

	UPROPERTY(DefaultComponent, Attach = Root)
	USceneComponent VineRoot2;

	UPROPERTY(DefaultComponent, Attach = VineRoot1)
	UBoxComponent BlockingComp1;
	default BlockingComp1.SetCollisionResponseToAllChannels(ECollisionResponse::ECR_Block);

	UPROPERTY(DefaultComponent, Attach = VineRoot2)
	UBoxComponent BlockingComp2;
	default BlockingComp2.SetCollisionResponseToAllChannels(ECollisionResponse::ECR_Block);

	UPROPERTY(DefaultComponent)
	UAdultDragonSiteHornResponseComponent HornResponseComp;

	UPROPERTY()
	float MoveAmount = 6000.0;

	bool bHornBlown;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		HornResponseComp.OnAdultDragonSiteHornCompleted.AddUFunction(this, n"OnAdultDragonSiteHornCompleted");
	}

	UFUNCTION()
	private void OnAdultDragonSiteHornCompleted(FVector CentralLocation)
	{
		BP_ActivateVineOpen();
	}

	UFUNCTION(BlueprintEvent)
	void BP_ActivateVineOpen() {}
}