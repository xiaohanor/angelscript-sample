class ASolarFlareGreenhouseShutterManager : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

#if EDITOR
	UPROPERTY(DefaultComponent, Attach = Root)
	UBillboardComponent Visual;
	default Visual.SetWorldScale3D(FVector(5));
#endif

	TArray<ASolarFlareGreenhouseShutter> ShutterArray;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		ShutterArray = TListedActors<ASolarFlareGreenhouseShutter>().GetArray();
	}

	UFUNCTION()
	void ActivateShutters()
	{
		for (ASolarFlareGreenhouseShutter Shutter : ShutterArray)
		{
			Shutter.ActivateGreenhouseDoorsShutters();
		}
	}

	UFUNCTION()
	void SetEndState()
	{
		for (ASolarFlareGreenhouseShutter Shutter : ShutterArray)
		{
			Shutter.SetEndState();
		}
	}
};