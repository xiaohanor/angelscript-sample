class ASpaceWalkDangerousDebris : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent)
	UStaticMeshComponent Debris;

	UPROPERTY(DefaultComponent)
	UNiagaraComponent Fire;

	float RandomScale;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		RandomScale = Math::RandRange(0.5,1.0);

		SetActorRelativeScale3D(FVector(RandomScale,RandomScale,RandomScale));
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		AddActorLocalRotation(FRotator(2,5,5) * DeltaSeconds);
	}
};