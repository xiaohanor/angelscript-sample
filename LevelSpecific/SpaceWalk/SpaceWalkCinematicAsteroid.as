class ASpaceWalkCinematicAsteroid : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent)
	UStaticMeshComponent Asteroid;

	UPROPERTY(DefaultComponent)
	UNiagaraComponent Fire;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		Asteroid.AddLocalRotation(FRotator(1,2,2));
	}
};