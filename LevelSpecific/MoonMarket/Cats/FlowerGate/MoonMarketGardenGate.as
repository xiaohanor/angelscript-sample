
class AMoonMarketGardenGate : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	USceneComponent RRoot;
	
	UPROPERTY(DefaultComponent, Attach = RRoot)
	UStaticMeshComponent RGate;
	
	UPROPERTY(DefaultComponent, Attach = Root)
	USceneComponent LRoot;

	UPROPERTY(DefaultComponent, Attach = LRoot)
	UStaticMeshComponent LGate;

	UPROPERTY(DefaultComponent, Attach = Root)
	UNiagaraComponent SymbolEffect;
	default SymbolEffect.SetAutoActivate(false);

	UPROPERTY(DefaultComponent, Attach = Root)
	UStaticMeshComponent Symbol;
	default Symbol.SetCollisionEnabled(ECollisionEnabled::NoCollision);

	UPROPERTY(DefaultComponent, Attach = Root)
	UStaticMeshComponent BackgroundForSymbol;
	default BackgroundForSymbol.SetCollisionEnabled(ECollisionEnabled::NoCollision);

	UPROPERTY(DefaultComponent, Attach = Root)
	UHazeCameraComponent Camera;

	UPROPERTY(DefaultComponent)
	UMoonMarketCatProgressComponent CatProgressComp;

	UPROPERTY(EditAnywhere)
	AMoonMarketCat DedicatedCat;

	UPROPERTY(EditDefaultsOnly)
	TSubclassOf<UCameraShakeBase> CameraShake;

	UPROPERTY(EditDefaultsOnly)
	UForceFeedbackEffect Rumble;

	UPROPERTY()
	FRuntimeFloatCurve DoorOpenCurve;

	bool bOpeningDoor;

	float Alpha;
	float Speed = 0.3;

	float RotateAmount = 85.0; 

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		TListedActors<AFlowerCatPuzzle>().Single.OnFlowerCatPuzzleCompleted.AddUFunction(this, n"OpenDoor");
		Symbol.SetHiddenInGame(true);
		SetActorTickEnabled(false);
		CatProgressComp.OnProgressionActivated.AddUFunction(this, n"OnProgressionActivated");
		DedicatedCat.OnMoonCatSoulCaught.AddUFunction(this, n"OnMoonCatSoulCaught");
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		if (bOpeningDoor && Alpha < 1.0)
		{
			Alpha += Speed * DeltaSeconds;
			Alpha = Math::Clamp(Alpha, 0, 1);
			float Curve = DoorOpenCurve.GetFloatValue(Alpha);
			RRoot.RelativeRotation = FRotator(0, RotateAmount * Curve, 0.0);
			LRoot.RelativeRotation = FRotator(0, -RotateAmount * Curve, 0.0);
		}
		else if (!bOpeningDoor && Alpha > 0.0)
		{
			Alpha -= Speed * DeltaSeconds;
			Alpha = Math::Clamp(Alpha, 0, 1);
			float Curve = DoorOpenCurve.GetFloatValue(Alpha);
			RRoot.RelativeRotation = FRotator(0, RotateAmount * Curve, 0.0);
			LRoot.RelativeRotation = FRotator(0, -RotateAmount * Curve, 0.0);			
		}

	}

	UFUNCTION()
	private void OnMoonCatSoulCaught(AHazePlayerCharacter Player, AMoonMarketCat Cat)
	{
		CloseGate();
	}

	UFUNCTION()
	private void OnProgressionActivated()
	{
		RRoot.RelativeRotation = FRotator(0, RotateAmount, 0.0);
		LRoot.RelativeRotation = FRotator(0, -RotateAmount, 0.0);		
		SetActorTickEnabled(false);
	}

	UFUNCTION()
	private void OpenDoor()
	{			
		for (AHazePlayerCharacter Player : Game::Players)
		{
			Player.ActivateCamera(Camera, 3.0, this);
			Timer::SetTimer(this, n"RemovePattern", 2.5);
			Timer::SetTimer(this, n"OpenGate", 3.0);
			Timer::SetTimer(this, n"DeactivateCamera", 4.0);
		}
	}

	UFUNCTION()
	void ShowPattern()
	{
		Symbol.SetHiddenInGame(false);
		SymbolEffect.Activate();
	}

	UFUNCTION()
	private void RemovePattern()
	{
		UMoonMarketGardenGateEventHandler::Trigger_OnPatternRemoved(this);
		Symbol.SetHiddenInGame(true);
		BackgroundForSymbol.SetHiddenInGame(true);
		Symbol.SetCollisionEnabled(ECollisionEnabled::NoCollision);
		SymbolEffect.Activate();
	}

	UFUNCTION()
	private void OpenGate()
	{
		UMoonMarketGardenGateEventHandler::Trigger_OnGateOpened(this);
		bOpeningDoor = true;
		SetActorTickEnabled(true);

		for (AHazePlayerCharacter Player : Game::Players)
		{
			Player.PlayCameraShake(CameraShake, this);
			Player.PlayForceFeedback(Rumble, false, false, this);
		}
	}

	UFUNCTION()
	private void CloseGate()
	{
		bOpeningDoor = false;
	}

	UFUNCTION()
	private void DeactivateCamera()
	{
		for (AHazePlayerCharacter Player : Game::Players)
		{
			Player.DeactivateCameraByInstigator(this, 2.5);
		}
	}
};