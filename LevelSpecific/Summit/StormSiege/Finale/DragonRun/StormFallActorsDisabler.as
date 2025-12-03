class AStormFallActorsDisabler : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	UBillboardComponent Visual;
	default Visual.SetWorldScale3D(FVector(18.0));

	UFUNCTION()
	void DeactivateStormFallObjectSpawners()
	{
		TListedActors<AStormFallObjectSpawner> StormOFallbjectSpawners; 
		TListedActors<AStormFallRockSpawner> StormFallRockSpawners;
		TListedActors<AStormFallObject> StormFallObjects;
		TListedActors<AStormFallRock> StormFallRocks;

		for (AStormFallObjectSpawner Spawner : StormOFallbjectSpawners)
			Spawner.DeactivateSpawner();

		for (AStormFallRockSpawner Spawner : StormFallRockSpawners)
			Spawner.DeactivateStormRockSpawner();

		for (AStormFallObject Object : StormFallObjects)
			Object.DestroyActor();

		for (AStormFallRock Rock : StormFallRocks)
			Rock.Params.FallSpeed = 0.0;
	}
}