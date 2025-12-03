class AGiantBell : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	UFauxPhysicsConeRotateComponent FauxConeComp;
	default FauxConeComp.RelativeRotation = FRotator(180, 0, 0);

	UPROPERTY(DefaultComponent, Attach = FauxConeComp)
	UStaticMeshComponent BellMesh;

	UPROPERTY(EditInstanceOnly)
	ADoubleInteractionActor DoubleInteract;

	UPROPERTY()
	TSubclassOf<UCameraShakeBase> GiantRevealCameraShake;

	UPROPERTY(EditAnywhere)
	UForceFeedbackEffect BellSlamFF;
	
	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		DoubleInteract.OnDoubleInteractionCompleted.AddUFunction(this, n"OnDoubleInteractionCompleted");
		DoubleInteract.OnPlayerStartedInteracting.AddUFunction(this, n"PlayerStartedInteract");
		DoubleInteract.OnCancelBlendingIn.AddUFunction(this, n"PlayerStoppedInteract");
	}

	UFUNCTION()
	private void PlayerStartedInteract(AHazePlayerCharacter Player, ADoubleInteractionActor Interaction,
	                                   UInteractionComponent InteractionComponent)
	{
		if(Player == Game::GetMio())
		{
			OpenRightLock();
		}
		else
		{
			OpenLeftLock();
		}
	}

	UFUNCTION()
	private void PlayerStoppedInteract(AHazePlayerCharacter Player, ADoubleInteractionActor Interaction,
	                                   UInteractionComponent InteractionComponent)
	{
		if(Player == Game::GetMio())
		{
			CloseRightLock();
		}
		else
		{
			CloseLeftLock();
		}
	}

	UFUNCTION()
	void OnDoubleInteractionCompleted()
	{
	}

	UFUNCTION(BlueprintCallable)
	void SlamTheBell()
	{
		FauxConeComp.ApplyForce(Game::GetMio().ActorLocation, FVector(25000, 0, 0));
		Game::GetMio().PlayCameraShake(GiantRevealCameraShake, this);
		Game::GetZoe().PlayCameraShake(GiantRevealCameraShake, this);
		Game::GetMio().PlayForceFeedback(BellSlamFF, this);
		Game::GetZoe().PlayForceFeedback(BellSlamFF, this);

		StartPointOfInterest();
	}

	UFUNCTION(BlueprintEvent)
	void OpenLeftLock()
	{

	}

	UFUNCTION(BlueprintEvent)
	void OpenRightLock()
	{
		
	}

	UFUNCTION(BlueprintEvent)
	void CloseLeftLock()
	{

	}

	UFUNCTION(BlueprintEvent)
	void CloseRightLock()
	{
		
	}

	UFUNCTION(BlueprintEvent)
	void StartPointOfInterest()
	{

	}
};