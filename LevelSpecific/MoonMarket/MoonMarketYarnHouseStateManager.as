class AMoonMarketYarnHouseStateManager : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

#if EDITOR
	UPROPERTY(DefaultComponent, Attach = Root)
	UBillboardComponent Visual;
	default Visual.SetWorldScale3D(FVector(2));
#endif

	UPROPERTY(DefaultComponent)
	UMoonMarketCatProgressComponent ProgComp;

	UPROPERTY(EditAnywhere)
	AMoonMarketBabaYagaLantern Lantern1;

	UPROPERTY(EditAnywhere)
	AMoonMarketBabaYagaLantern Lantern2;

	UPROPERTY(EditAnywhere)
	AActor Door;

	UPROPERTY(EditAnywhere)
	ADoubleInteractionActor DoubleInteract;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		ProgComp.OnProgressionActivated.AddUFunction(this, n"OnProgressionActivated");
	}

	UFUNCTION()
	private void OnProgressionActivated()
	{
		DoubleInteract.AddActorDisable(this);
		Lantern1.SetEndState();
		Lantern2.SetEndState();
		Door.AddActorWorldRotation(FRotator(0,110,0));
	}
};