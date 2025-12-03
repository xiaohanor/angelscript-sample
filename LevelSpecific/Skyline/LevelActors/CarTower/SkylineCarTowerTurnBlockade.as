class ASkylineCarTowerTurnBlockade : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent)
	USkylineBallBossLaserResponseComponent LaserComp;

	UPROPERTY(DefaultComponent)
	USkylineInterfaceComponent InterFaceComp;

	bool bDoOnce = true;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		LaserComp.OnLaserOverlap.AddUFunction(this, n"HandleOnLaserOverlap");
	}

	UFUNCTION(BlueprintEvent)
	void HandleOnLaserOverlap(bool bOverlap)
	{
		if(bDoOnce)
		{
			InterFaceComp.TriggerActivate();
			bDoOnce = false;
		}
		
	}
};