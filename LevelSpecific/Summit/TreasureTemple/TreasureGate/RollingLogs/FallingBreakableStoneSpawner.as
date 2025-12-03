class AFallingBreakableStoneSpawner : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	UBillboardComponent VisualComp;
	default VisualComp.SetWorldScale3D(FVector(5.0));

	UPROPERTY()
	TSubclassOf<AFallingBreakableStones> BreakableStoneClass;

	float SpawnRate = 1.75;
	float SpawnTime;
	float DelayTime;
	float MaxDelay = 3.5;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		SetActorTickEnabled(false);
	}

	UFUNCTION()
	void BeginSpawn()
	{
		SetActorTickEnabled(true);
		DelayTime = Math::RandRange(0.0, MaxDelay);
		SpawnTime = Time::GameTimeSeconds + DelayTime + SpawnRate;
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		if (Time::GameTimeSeconds > SpawnTime)
		{
			SpawnTime = Time::GameTimeSeconds + SpawnRate;
			SpawnActor(BreakableStoneClass, ActorLocation);
		}
	}
}