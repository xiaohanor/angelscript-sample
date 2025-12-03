class AMeltdownSplitSlideSkydiveCurrent : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	UBoxComponent TriggerComp;
	default TriggerComp.SetCollisionProfileName(n"TriggerOnlyPlayer");

	UPROPERTY(EditAnywhere)
	float CurrentStrength = 1000.0;

	TPerPlayer<bool> bPlayerOverlapping;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		TriggerComp.OnComponentBeginOverlap.AddUFunction(this, n"HandleBeginOverlap");
		TriggerComp.OnComponentEndOverlap.AddUFunction(this, n"HandleEndOverlap");
		SetActorTickEnabled(false);
	}

	UFUNCTION()
	private void HandleEndOverlap(UPrimitiveComponent OverlappedComponent, AActor OtherActor,
	                              UPrimitiveComponent OtherComp, int OtherBodyIndex)
	{
		auto Player = Cast<AHazePlayerCharacter>(OtherActor);
		if (Player != nullptr)
			bPlayerOverlapping[Player] = false;
	}

	UFUNCTION()
	private void HandleBeginOverlap(UPrimitiveComponent OverlappedComponent, AActor OtherActor,
	                                UPrimitiveComponent OtherComp, int OtherBodyIndex, bool bFromSweep,
	                                const FHitResult&in SweepResult)
	{
		auto Player = Cast<AHazePlayerCharacter>(OtherActor);
		if (Player != nullptr)
			bPlayerOverlapping[Player] = true;
	}

	UFUNCTION()
	void Activate()
	{
		SetActorTickEnabled(true);
	}

	UFUNCTION()
	void Deactivate()
	{
		SetActorTickEnabled(false);
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		for (auto Player : Game::GetPlayers())
		{
			if (bPlayerOverlapping[Player])
				continue;

			FVector Direction = (ActorLocation - Player.ActorLocation).VectorPlaneProject(FVector::UpVector).GetSafeNormal();
			Player.AddMovementImpulse(Direction * CurrentStrength * DeltaSeconds);

			PrintToScreen("Impulse" + (Direction * CurrentStrength));
		}

		PrintToScreenScaled("Active");
	}
};