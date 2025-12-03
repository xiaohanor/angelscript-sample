class AForgeGoldSpawner : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	USceneComponent Spawnpoint;

	UPROPERTY(EditAnywhere)
	ASplineActor SplineActor;

	UPROPERTY(DefaultComponent, Attach = Spawnpoint)
	UBillboardComponent SpawnBillboard;

	FVector Spawnlocation;

	float TimeToSpawn;

	float SpawnInterval = 10.0;

	UPROPERTY()
	TSubclassOf<AForgeGoldConveyor> GoldConveyorClass;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		Spawnlocation = Spawnpoint.GetWorldLocation();

	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		if (Time::GetGameTimeSeconds() > TimeToSpawn)
		{
			TimeToSpawn = Time::GetGameTimeSeconds() + SpawnInterval;
			AForgeGoldConveyor NewConveyor = Cast<AForgeGoldConveyor> (SpawnActor(GoldConveyorClass,Spawnlocation, bDeferredSpawn = true));
			NewConveyor.SplineComp = SplineActor.Spline;
			FinishSpawningActor(NewConveyor);
		}

	}
	
}