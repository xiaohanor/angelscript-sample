class ASkylineBossDeathSphere : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	float Duration = 10.0;

	float Scale = 1.0;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		Scale = ActorScale3D.X;
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		Scale += DeltaSeconds * 10.0;
		ActorScale3D = FVector::OneVector * Scale;
	
		if (GameTimeSinceCreation > Duration)
			DestroyActor();
	}
};