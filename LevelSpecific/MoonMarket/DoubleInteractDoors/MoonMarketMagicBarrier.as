event void FOnMoonMarketMagicBarrierCleared();

class AMoonMarketMagicBarrier : AHazeActor
{
	UPROPERTY()
	FOnMoonMarketMagicBarrierCleared OnMoonMarketMagicBarrierCleared;

	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	USceneComponent DoorRotateRoot;

	UPROPERTY(DefaultComponent, Attach = DoorRotateRoot)
	UStaticMeshComponent MeshComp;

	UPROPERTY(EditInstanceOnly)
	ADoubleInteractionActor DoubleInteract;

	UPROPERTY(EditInstanceOnly)
	APlayerTrigger PlayerTrigger;

	UPROPERTY(EditInstanceOnly)
	TPerPlayer<AMoonMarketBabaYagaLantern> Lanterns;

	UPROPERTY(EditInstanceOnly)
	AYarnCatManager YarnCatManager;

	FRotator EndRotation = FRotator(0,110,0);

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		DoubleInteract.OnDoubleInteractionCompleted.AddUFunction(this, n"OnDoubleInteractionCompleted");

		DoubleInteract.LeftInteraction.OnInteractionStarted.AddUFunction(this, n"OnInteractionStarted");
		DoubleInteract.RightInteraction.OnInteractionStarted.AddUFunction(this, n"OnInteractionStarted");

		DoubleInteract.LeftInteraction.OnInteractionStopped.AddUFunction(this, n"OnInteractionStopped");
		DoubleInteract.RightInteraction.OnInteractionStopped.AddUFunction(this, n"OnInteractionStopped");

		PlayerTrigger.AddActorDisable(this);
	}

	UFUNCTION()
	private void OnInteractionStarted(UInteractionComponent InteractionComponent,
	                                  AHazePlayerCharacter Player)
	{
	}

	UFUNCTION()
	private void OnInteractionStopped(UInteractionComponent InteractionComponent,
	                                  AHazePlayerCharacter Player)
	{
	}

	UFUNCTION()
	private void OnDoubleInteractionCompleted()
	{
		ActivateQuest();
		Lanterns[0].ActivateLantern();
		Lanterns[1].ActivateLantern();

		OnMoonMarketMagicBarrierCleared.Broadcast();
	}

	UFUNCTION()
	void UnhidePropLine()
	{
		PlayerTrigger.RemoveActorDisable(this);
	}

	UFUNCTION()
	void SetDoorOpen()
	{
		DoorRotateRoot.SetRelativeRotation(EndRotation);
	}

	UFUNCTION()
	void ActivateQuest()
	{
		DoubleInteract.DisableDoubleInteraction(this);
		YarnCatManager.ActivateCats();

		for (AHazePlayerCharacter Player : Game::Players)
			Player.ClearCameraSettingsByInstigator(this);
	}
};