class AStormChaseRockSpawner : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	USceneComponent MeshRoot;

	UPROPERTY(DefaultComponent, Attach = Root)
	UBillboardComponent Visual;
	default Visual.SetWorldScale3D(FVector(20.0));

	UPROPERTY(EditAnywhere, Meta = (MakeEditWidget))
	TArray<FVector> Locations;

	UPROPERTY()
	TSubclassOf<AStormChaseFallingRock> FallingRockClass;

	UPROPERTY()
	UNiagaraSystem RockExplosionSystem;

	void SpawnRocks()
	{
		for (FVector Loc : Locations)
		{
			SpawnActor(FallingRockClass, Loc);
			Niagara::SpawnOneShotNiagaraSystemAtLocation(RockExplosionSystem, Loc);
		}
	}
}