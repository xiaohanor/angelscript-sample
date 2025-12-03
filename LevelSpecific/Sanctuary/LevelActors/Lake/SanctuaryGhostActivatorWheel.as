class ASanctuaryGhostActivatorWheel : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent)
	ULightBirdResponseComponent RespComp;

	UPROPERTY(EditAnywhere)
	AHazeActorSingleSpawner GhostSpawner;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		RespComp.OnIlluminated.AddUFunction(this, n"HandleIlluminated");
	}

	UFUNCTION()
	private void HandleIlluminated()
	{
		if(GhostSpawner.SpawnerComp.bStartActivated==false)
		{
			GhostSpawner.SpawnerComp.ActivateSpawner(this);
		}
	}
};