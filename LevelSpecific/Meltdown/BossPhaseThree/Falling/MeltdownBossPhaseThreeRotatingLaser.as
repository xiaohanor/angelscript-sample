class AMeltdownBossPhaseThreeRotatingLaser : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent)
	UStaticMeshComponent SpinCube;
	default SpinCube.SetHiddenInGame(true);
	default SpinCube.SetCollisionEnabled(ECollisionEnabled::NoCollision);

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		AddActorLocalRotation(FRotator(0, 30,0) * DeltaSeconds);
	}
};