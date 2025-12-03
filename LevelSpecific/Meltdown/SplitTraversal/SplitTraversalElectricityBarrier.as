class ASplitTraversalElectricityBarrier : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

#if EDITOR
	UPROPERTY(DefaultComponent)
	UEditorBillboardComponent Billboard;
#endif

	UPROPERTY(DefaultComponent)
	UBoxComponent KillBox;

	UPROPERTY(EditAnywhere)
	AOneShotInteractionActor DisableInteraction;
	UPROPERTY(EditAnywhere)
	AHazeCameraActor Camera;
	UPROPERTY(EditAnywhere)
	TSubclassOf<AActor> PickupClass;

	AActor Pickup;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		KillBox.OnComponentBeginOverlap.AddUFunction(this, n"OnOverlapKillBox");
		DisableInteraction.OnOneShotActivated.AddUFunction(this, n"OnOneShotStarted");
		DisableInteraction.OnOneShotFinished.AddUFunction(this, n"OnDisableFinished");
	}

	UFUNCTION()
	private void OnOneShotStarted(AHazePlayerCharacter Player, AOneShotInteractionActor Interaction)
	{
		Timer::SetTimer(this, n"GrabPickup", 0.5);
		Timer::SetTimer(this, n"ReleasePickup", 1.5);

		Game::Mio.ActivateCamera(Camera, 1.0, this);
		Game::Mio.BlockCapabilities(n"Input", this);
	}


	UFUNCTION()
	private void GrabPickup()
	{
		auto Player = Game::Zoe;
		Pickup = SpawnActor(PickupClass, Player.ActorLocation);
		Pickup.AttachToComponent(Player.Mesh, n"RightHand");
	}

	UFUNCTION()
	private void ReleasePickup()
	{
		Pickup.DetachRootComponentFromParent();
		
		TArray<UPrimitiveComponent> Primitives;
		Pickup.GetComponentsByClass(Primitives);

		for (auto Prim : Primitives)
		{
			Prim.SetSimulatePhysics(true);
			Prim.AddImpulse(FVector(0, 0, 20), bVelChange = true);
		}

		Game::Mio.DeactivateCamera(Camera, 2.0);
		Game::Mio.UnblockCapabilities(n"Input", this);
	}

	UFUNCTION()
	private void OnDisableFinished(AHazePlayerCharacter Player, AOneShotInteractionActor Interaction)
	{
		TurnOffElectricity();
	}

	UFUNCTION()
	void TurnOffElectricity()
	{
		AddActorDisable(this);
		DisableInteraction.Interaction.Disable(n"Finished");
		KillBox.SetCollisionEnabled(ECollisionEnabled::NoCollision);
	}

	UFUNCTION()
	private void OnOverlapKillBox(UPrimitiveComponent OverlappedComponent, AActor OtherActor,
	                              UPrimitiveComponent OtherComp, int OtherBodyIndex, bool bFromSweep,
	                              const FHitResult&in SweepResult)
	{
		auto Player = Cast<AHazePlayerCharacter>(OtherActor);
		if (Player != nullptr)
			Player.KillPlayer();
	}
};