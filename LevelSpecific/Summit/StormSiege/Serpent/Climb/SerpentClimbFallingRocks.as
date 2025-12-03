class ASerpentClimbFallingRocks : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	USceneComponent MeshRoot;

	float LifeTime = 10.0;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		SetActorTickEnabled(false);
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		ActorLocation -= FVector::UpVector * 1500.0 * DeltaSeconds;

		LifeTime -= DeltaSeconds;

		if (LifeTime <= 0.0)
			DestroyActor();
	}

	UFUNCTION()
	void ActivateFallingRock()
	{
		SetActorTickEnabled(true);
	}
};