class ASummitClimbingMetalSpawner : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	USceneComponent SpawnPoint;

	UPROPERTY(EditAnywhere)
	ASplineActor SplineActor;

	UPROPERTY(DefaultComponent, Attach = SpawnPoint)
	UBillboardComponent SpawnVisualizer;

	FVector Spawnlocation;

	float SpawnTimer;

	float SpawnWait = 5.0;

	UPROPERTY()
	TSubclassOf<ASummitClimbingMetalSpline> ClimbingSpline;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		Spawnlocation = SpawnPoint.GetWorldLocation();
	}
	
}