class ASkylineWhipObjectSpawner : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent)
	UArrowComponent Arrow;

	UPROPERTY(DefaultComponent)
	UDisableComponent DisableComp;
	default DisableComp.bAutoDisable = true;
	default DisableComp.AutoDisableRange = 10000.0;

	UPROPERTY(EditAnywhere)
	bool bStartActivated = true;

	UPROPERTY(EditAnywhere)
	int NumToSpawn = 1;

	UPROPERTY(EditAnywhere)
	float SpawnInterval = 1.0;

	UPROPERTY(EditAnywhere)
	float SpawnVelocity = 0.0;

	UPROPERTY(EditAnywhere)
	float MaxRandomAngle = 0.0;

	UPROPERTY(EditAnywhere)
	float MaxRandomVelocity = 0.0;

	UPROPERTY(EditAnywhere)
	TSubclassOf<AWhipSlingableObject> WhipSlingableObjectClass;

	UPROPERTY(EditAnywhere)
	TArray<AActor> ActorsToIgnore;

	FTimerHandle Timer;
	bool bActive = false;

	UHazeActorNetworkedSpawnPoolComponent SpawnPool;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		SetActorControlSide(Game::Zoe);
		SpawnPool = HazeActorNetworkedSpawnPoolStatics::GetOrCreateSpawnPool(WhipSlingableObjectClass, this);

		if (bStartActivated)
		{
			bActive = true;
			SetTimer();
		}
	}

	void SetTimer()
	{
		Timer = Timer::SetTimer(this, n"SpawnObject", SpawnInterval, true);
	}

	UFUNCTION()
	void Activate()
	{
		bActive = true;
		if (!IsActorDisabled())
		{
			if (!Timer.IsValid())
				SetTimer();

			Timer.UnPauseTimer();
		}
	}

	UFUNCTION()
	void Deactivate()
	{
		bActive = false;
		if (!IsActorDisabled())
			Timer.PauseTimer();		
	}

	UFUNCTION(BlueprintOverride)
	void OnActorEnabled()
	{
		if (bActive)
			SetTimer();
	}

	UFUNCTION(BlueprintOverride)
	void OnActorDisabled()
	{
		Timer.ClearTimerAndInvalidateHandle();
	}

	UFUNCTION()
	void SpawnObject()
	{
		if (!HasControl())
			return;

		TArray<AWhipSlingableObject> Objects;
		for (int i = 0; i < NumToSpawn; i++)
		{
			FHazeActorSpawnParameters Params;
			Params.Location = ActorLocation;
			Params.Rotation = ActorRotation;
			Objects.Add(
				Cast<AWhipSlingableObject>(SpawnPool.SpawnControl(Params))
			);
		}

		CrumbSpawnObjects(Objects);
	}

	UFUNCTION(CrumbFunction)
	void CrumbSpawnObjects(TArray<AWhipSlingableObject> Objects)
	{
		TArray<AActor> SpawnedWhipSlingableObjects;
		TArray<UHazeMovementComponent> MovementComponents;

		for (int i = 0; i < Objects.Num(); i++)
		{
			auto WhipSlingableObject = Objects[i];

			WhipSlingableObject.RemoveActorDisable(n"UnSpawned");
			WhipSlingableObject.bGrabbed = true;
			WhipSlingableObject.bThrown = true;
			WhipSlingableObject.AngularVelocity = ActorTransform.InverseTransformVectorNoScale(ActorRightVector * 10.0);
			WhipSlingableObject.DisableComp.SetEnableAutoDisable(false);
			WhipSlingableObject.SpawnPool = SpawnPool;
			// WhipSlingableObject.InitialMovementIgnoreActors = ActorsToIgnore;

			FVector Direction = Math::GetRandomConeDirection(ActorForwardVector, Math::DegreesToRadians(MaxRandomAngle), 0.0);

			WhipSlingableObject.ActorVelocity = Direction * (SpawnVelocity + Math::RandRange(-MaxRandomVelocity, MaxRandomVelocity));

			SpawnedWhipSlingableObjects.Add(WhipSlingableObject);
			MovementComponents.Add(WhipSlingableObject.MovementComponent);
		}

		FTransform SpawnTransform = ActorTransform;

		for (int i = 0; i < SpawnedWhipSlingableObjects.Num(); i++)
		{
			auto WhipSlingableObject = SpawnedWhipSlingableObjects[i];
			// for (auto ActorToIgnore : SpawnedWhipSlingableObjects)
			// 	WhipSlingableObject.InitialMovementIgnoreActors.Add(ActorToIgnore);

			MovementComponents[i].RemoveMovementIgnoresComponents(this);
			MovementComponents[i].RemoveMovementIgnoresActor(this);
			MovementComponents[i].AddMovementIgnoresActors(this, SpawnedWhipSlingableObjects);
			MovementComponents[i].AddMovementIgnoresActors(this, ActorsToIgnore);

			// for (auto ActorToIgnore : SpawnedWhipSlingableObjects)
			// 	WhipSlingableObject.MovementComponent.AddMovementIgnoresActor(this, ActorToIgnore);	
		}
	
		// PrintToScreen("ObjectSpawned: " + WhipSlingableObject, 2.0, FLinearColor::Green);
	}
}