class ASerpentFallingFloor : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	UStaticMeshComponent MeshComp;

	UPROPERTY(DefaultComponent)
	UHazeListedActorComponent ListComp;

	UPROPERTY()
	UNiagaraSystem DustExplosion;

	FVector StartLoc;
	FVector EndLoc;

	float MinAccel = 30.0;
	float MaxAccel = 50.0;
	float FallAcceleration;
	float FallSpeed = 250.0;
	float CurrentFallSpeed = 0.0;

	float LifeTime = 2.0;
	
	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		FallAcceleration = Math::RandRange(MinAccel, MaxAccel);
		StartLoc = MeshComp.RelativeLocation;
		EndLoc = StartLoc + FVector(0.0, 0.0, -6000.0);
		SetActorTickEnabled(false);
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		CurrentFallSpeed = Math::FInterpConstantTo(CurrentFallSpeed, FallSpeed, DeltaSeconds, FallAcceleration);
		MeshComp.RelativeLocation = Math::VInterpConstantTo(MeshComp.RelativeLocation, EndLoc, DeltaSeconds, CurrentFallSpeed);
	
		LifeTime -= DeltaSeconds;

		PrintToScreen("MeshComp.RelativeLocation.Z: " + MeshComp.RelativeLocation.Z);

		if (LifeTime <= 0.0)
		{
			Niagara::SpawnOneShotNiagaraSystemAtLocation(DustExplosion, ActorLocation, ActorRotation);
			DestroyActor();
		}
	}

	void ActivateFalling()
	{
		SetActorTickEnabled(true);
	} 
};