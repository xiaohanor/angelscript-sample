class AStormFallObjectSpawnerManager : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

#if EDITOR
	UPROPERTY(DefaultComponent, Attach = Root)
	UBillboardComponent Visual;
	default Visual.SetWorldScale3D(FVector(50.0));
#endif

	TArray<AStormFallObjectSpawner> SpawnerArray;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
	}

	UFUNCTION()
	void StartObjectSpawning()
	{
		SpawnerArray = TListedActors<AStormFallObjectSpawner>().GetArray();
		
		for (AStormFallObjectSpawner Object : SpawnerArray)
		{
			Object.ActivateSpawner();
		}
	}

	UFUNCTION()
	void StopObjectSpawning()
	{
		SpawnerArray = TListedActors<AStormFallObjectSpawner>().GetArray();
		
		for (AStormFallObjectSpawner Object : SpawnerArray)
		{
			Object.DeactivateSpawner();
		}
	}
};