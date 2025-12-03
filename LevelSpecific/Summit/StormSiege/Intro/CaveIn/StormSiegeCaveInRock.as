class AStormSiegeCaveInRock : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	USceneComponent MeshRoot;

	float FallSpeed = 5000.0;

	float LifeTime = 10.0;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		LifeTime += Time::GameTimeSeconds;
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		ActorLocation -= FVector::UpVector * FallSpeed * DeltaSeconds;

		if (Time::GameTimeSeconds > LifeTime)
			DestroyActor();
	}
}