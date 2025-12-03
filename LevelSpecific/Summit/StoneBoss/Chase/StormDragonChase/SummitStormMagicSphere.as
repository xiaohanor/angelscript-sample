class ASummitStormMagicSphere : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	USceneComponent MeshRoot;

	UPROPERTY(DefaultComponent, Attach = Root)
	USphereComponent SphereComp;

	FVector FloatDirection;

	float MoveSpeed = 4000.0;
	float LifeTime = 8.0;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		SphereComp.OnComponentBeginOverlap.AddUFunction(this, n"OnComponentBeginOverlap");
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		ActorLocation += FloatDirection * MoveSpeed * DeltaSeconds;

		LifeTime -= DeltaSeconds;

		if (LifeTime <= 0.0)
			DestroyActor();
	}

	UFUNCTION()
	private void OnComponentBeginOverlap(UPrimitiveComponent OverlappedComponent, AActor OtherActor,
	                                     UPrimitiveComponent OtherComp, int OtherBodyIndex,
	                                     bool bFromSweep, const FHitResult&in SweepResult)
	{
		AAdultDragon AdultDragon = Cast<AAdultDragon>(OtherActor);

		if (AdultDragon == nullptr)
			return;

		FSummitMagicSphereImpact Params;
		Params.Location = ActorLocation;
		USummitStormMagicSphereEventHandler::Trigger_MagicSphereImpact(this, Params);
	}
}