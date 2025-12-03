class AStormCliffRockManager : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	UBillboardComponent Visual;
	default Visual.SetWorldScale3D(FVector(10.0));

	TArray<AStormCliffRock> Rocks;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		TArray<AActor> Actors;
		GetAttachedActors(Actors);
		for (AActor Actor : Actors)
		{
			auto Rock = Cast<AStormCliffRock>(Actor);
			if (Rock != nullptr)
				Rocks.Add(Rock);
		}
	}

	UFUNCTION()
	void ActivateRocks()
	{
		for (AStormCliffRock Rock : Rocks)
		{
			Rock.ActivateCliffRock();
		}
	}
};