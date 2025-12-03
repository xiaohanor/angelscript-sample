class AShipWreckageShell : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	UStaticMeshComponent MeshComp;
	default MeshComp.SetSimulatePhysics(true);

	UPROPERTY(DefaultComponent, Attach = MeshComp)
	USceneComponent ImpulseOrigin;

	float LifeTime = 4.0;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		LifeTime += Time::GameTimeSeconds;
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		if (Time::GameTimeSeconds > LifeTime)
			DestroyActor();
	}
}