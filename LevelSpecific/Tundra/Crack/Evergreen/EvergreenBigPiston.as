class AEvergreenBigPiston : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(EditAnywhere)
	bool bDoNotMove = false;

	UPROPERTY(EditAnywhere)
	AEvergreenLifeManager LifeManager;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		LifeManager.LifeComp.OnInteractStartDuringLifeGive.AddUFunction(this, n"ActivatePiston");
		LifeManager.LifeComp.OnInteractStopDuringLifeGive.AddUFunction(this, n"DeActivatePiston");
	}

	UFUNCTION(BlueprintEvent)
	void ActivatePiston()
	{

	}

	UFUNCTION(BlueprintEvent)
	void DeActivatePiston()
	{

	}
};