class AStoneBeastSpawningRock : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	USummitObjectBobbingComponent BobbingComp;

	UPROPERTY(DefaultComponent, Attach = BobbingComp)
	USceneComponent MeshRoot;

	UPROPERTY(DefaultComponent, Attach = MeshRoot)
	UStaticMeshComponent MeshComp;

	UPROPERTY(EditAnywhere)
	ASerpentEventActivator SerpentEvent;

	UPROPERTY()
	UNiagaraSystem SpawnEffect;

	FVector StartScale;

	float RotationSpeed = 15.0;

	float RPitch;
	float RYaw;
	float RRoll;
	float RSpeed;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		StartScale = MeshRoot.RelativeScale3D;
		MeshRoot.RelativeScale3D = FVector(0.05);

		RPitch = Math::RandRange(-1.0, 1.0);
		RYaw = Math::RandRange(-1.0, 1.0);
		RRoll = Math::RandRange(-1.0, 1.0);
		RSpeed = Math::RandRange(10.0, 20.0);

		BobbingComp.BobbingAmount = Math::RandRange(100.0, 200.0);
		BobbingComp.BobbingSpeed = Math::RandRange(1.0, 1.5);

		MeshRoot.SetHiddenInGame(true);
		SerpentEvent.OnSerpentEventTriggered.AddUFunction(this, n"OnSerpentEventTriggered");

		SetActorTickEnabled(false);
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		MeshRoot.RelativeScale3D = Math::VInterpTo(MeshRoot.RelativeScale3D, StartScale, DeltaSeconds, 1.5);
		MeshRoot.AddLocalRotation(FRotator(RPitch, RYaw, RRoll) * RSpeed * DeltaSeconds);
	}

	UFUNCTION()
	void ActivateRock()
	{
		SetActorTickEnabled(true);
		Niagara::SpawnOneShotNiagaraSystemAtLocation(SpawnEffect, ActorLocation);
		MeshRoot.SetHiddenInGame(false);
	}

	UFUNCTION()
	private void OnSerpentEventTriggered()
	{
		ActivateRock();
	}
};