class ATreasureTempleArenaMagicWave : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	USceneComponent MeshRoot;

	UPROPERTY(DefaultComponent, Attach = Root)
	UBoxComponent KillBox;
	default KillBox.SetCollisionResponseToAllChannels(ECollisionResponse::ECR_Ignore);
	default KillBox.SetCollisionResponseToChannel(ECollisionChannel::PlayerCharacter, ECollisionResponse::ECR_Overlap);

	UPROPERTY()
	TSubclassOf<UCameraShakeBase> RollingCamShake;

	//TArray<ABreakableIndividualFloor> BreakableFloors;

	float Speed = 2500.0;

	float LifeTime = 5.0;

	FVector StartLocation;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		StartLocation = ActorLocation;
		//GetAllActorsOfClass(BreakableFloors);
		KillBox.OnComponentBeginOverlap.AddUFunction(this, n"OnComponentBeginOverlap");
		LifeTime += Time::GameTimeSeconds;
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		// Game::Mio.PlayWorldCameraShake(RollingCamShake, this, ActorLocation, 1500.0, 8000.0, Scale = 0.8);
		// Game::Zoe.PlayWorldCameraShake(RollingCamShake, this, ActorLocation, 1500.0, 8000.0, Scale = 0.8);
		
		ActorLocation += ActorForwardVector * Speed * DeltaSeconds;
	
		if (Time::GameTimeSeconds > LifeTime)
			DestroyActor();
	}
	
	UFUNCTION()
	private void OnComponentBeginOverlap(UPrimitiveComponent OverlappedComponent, AActor OtherActor,
	                                     UPrimitiveComponent OtherComp, int OtherBodyIndex,
	                                     bool bFromSweep, const FHitResult&in SweepResult)
	{
		AHazePlayerCharacter Player = Cast<AHazePlayerCharacter>(OtherActor);

		if (Player != nullptr)
		{
			if (!Player.IsPlayerDead())
				Player.KillPlayer();
		}
	}
}