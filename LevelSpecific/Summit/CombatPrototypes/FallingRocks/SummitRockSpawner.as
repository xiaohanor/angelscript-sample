class ASummitRockSpawner : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	UBillboardComponent VisualComp;

	UPROPERTY()
	TSubclassOf<ASummitFallingRock> FallingRockClass;

	UPROPERTY(EditAnywhere)
	float SpawnStartDelay;

	float Interval = 6.0;
	float SpawnTime;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		SetActorTickEnabled(false);
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		if (Time::GameTimeSeconds > SpawnTime)
		{
			SpawnActor(FallingRockClass, ActorLocation);
			SpawnTime = Time::GameTimeSeconds + Interval;
		}
	}

	UFUNCTION()
	void StartSpawn()
	{
		SpawnTime = Time::GameTimeSeconds + SpawnStartDelay;
		SetActorTickEnabled(true);
	}
}