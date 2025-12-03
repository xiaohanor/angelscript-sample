class AStoneBeastRisingRock : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	USceneComponent MeshRoot;

	UPROPERTY(DefaultComponent, Attach = MeshRoot)
	UStaticMeshComponent MeshComp;

	UPROPERTY(DefaultComponent, Attach = MeshRoot)
	USceneComponent EmergeSpawnLoc;

	UPROPERTY()
	TSubclassOf<UCameraShakeBase> CameraShake;

	UPROPERTY(EditAnywhere)
	ASerpentEventActivator SerpentEvent;

	UPROPERTY(EditAnywhere)
	APlayerTrigger PlayerTrigger;

	UPROPERTY(EditAnywhere)
	UNiagaraSystem EmergeSystem;

	UPROPERTY(EditAnywhere)
	float MoveAmount = 11500.0;

	UPROPERTY(EditAnywhere)
	float Speed = 18000.0;
	
	UPROPERTY(EditAnywhere)
	float DelayTime = 0.0;

	FVector StartLoc;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		StartLoc = ActorLocation;
		ActorLocation += -ActorUpVector * MoveAmount;
		SetActorTickEnabled(false);

		if (SerpentEvent != nullptr)
			SerpentEvent.OnSerpentEventTriggered.AddUFunction(this, n"RockActivated");

		if (PlayerTrigger != nullptr)
			PlayerTrigger.OnPlayerEnter.AddUFunction(this, n"OnPlayerEnter");
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		if (DelayTime > 0.0)
			DelayTime -= DeltaSeconds;
		else
			ActorLocation = Math::VInterpConstantTo(ActorLocation, StartLoc, DeltaSeconds, Speed);
	}

	UFUNCTION()
	private void OnPlayerEnter(AHazePlayerCharacter Player)
	{
		ActivateRisingRock();
	}

	UFUNCTION()
	void ActivateRisingRock()
	{
		SetActorTickEnabled(true);
		for (AHazePlayerCharacter Player : Game::Players)
			Player.PlayCameraShake(CameraShake, this, 2.0);

		UStonebeastRisingRockEventHandler::Trigger_RisingRockInitiate(this);
		// Niagara::SpawnOneShotNiagaraSystemAtLocation(EmergeSystem, EmergeSpawnLoc.WorldLocation, ActorRotation);
		// Niagara::SpawnOneShotNiagaraSystemAtLocation(EmergeSystem, EmergeSpawnLoc.WorldLocation + FVector(0,0,1200.0), ActorRotation);
		// Niagara::SpawnOneShotNiagaraSystemAtLocation(EmergeSystem, EmergeSpawnLoc.WorldLocation + FVector(-1000,-1500,0), ActorRotation);
		// Niagara::SpawnOneShotNiagaraSystemAtLocation(EmergeSystem, EmergeSpawnLoc.WorldLocation + FVector(1000,1500,0), ActorRotation);
	}

	UFUNCTION()
	private void RockActivated()
	{
		ActivateRisingRock();
	}
};