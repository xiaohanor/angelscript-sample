class ASanctuaryBossOrbit : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(EditAnywhere)
	float Speed = 1.0;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		ActorRotation = FRotator(0.0, Speed * Time::GameTimeSeconds, 0.0);
	}
};