event void FOnTownSquareGateOpened();

class ATownSquareCatIntroGate : AHazeActor
{
	UPROPERTY()
	FOnTownSquareGateOpened OnTownSquareGateOpened; 

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

	UPROPERTY(EditInstanceOnly)
	ADoubleInteractionActor DoubleInteract;

	UPROPERTY()
	FRuntimeFloatCurve DoorOpenCurve;

	float Alpha;
	float Speed = 0.5;

	float RotateAmount = 90.0; 

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		DoubleInteract.OnDoubleInteractionCompleted.AddUFunction(this, n"OnDoubleInteractionCompleted");
		SetActorTickEnabled(false);
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		Alpha += Speed * DeltaSeconds;
		Alpha = Math::Clamp(Alpha, 0, 1);
		float Curve = DoorOpenCurve.GetFloatValue(Alpha);
		RRoot.RelativeRotation = FRotator(0, RotateAmount * Alpha, 0.0);
		LRoot.RelativeRotation = FRotator(0, -RotateAmount * Alpha, 0.0);

		if (Alpha == 1)
			SetActorTickEnabled(false);
	}

	UFUNCTION()
	private void OnDoubleInteractionCompleted()
	{
		OpenDoor();
		DoubleInteract.AddActorDisable(this);
		OnTownSquareGateOpened.Broadcast();
	}

	private void OpenDoor()
	{	
		SetActorTickEnabled(true);
	}
};

