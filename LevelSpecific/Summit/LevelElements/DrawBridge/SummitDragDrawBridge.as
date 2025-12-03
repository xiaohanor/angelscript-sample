class ASummitDragDrawBridge : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent)
	USceneComponent BridgeRotateRoot;

	UPROPERTY(DefaultComponent)
	USceneComponent TestBridgeRotateRoot;

	UPROPERTY(EditAnywhere)
	AActor TestBridgeForVFX;

	UPROPERTY(EditInstanceOnly, Category = "Setup")
	ASummitDragDrawBridgePulley Pulley;	

	UPROPERTY(EditInstanceOnly, Category = "Setup")
	TArray<AActor> WheelsToRotate;

	UPROPERTY(EditAnywhere, Category = "Settings")
	float WheelRotateDegreesMax = -720.0;

	TMap<AActor, FRotator> WheelStartRotations;

	float StartBridgeRotationDegrees;
	float MaxPitchAmount = 55.0;


	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		for(auto Wheel : WheelsToRotate)
		{
			WheelStartRotations.Add(Wheel, Wheel.ActorRotation);
		}

		StartBridgeRotationDegrees = BridgeRotateRoot.RelativeRotation.Pitch;
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		if(Pulley == nullptr)
			return;
		
		float LerpedPitch = Math::Lerp(MaxPitchAmount, StartBridgeRotationDegrees, Pulley.PulleyAlpha);
		FRotator NewBridgeRotation = FRotator(LerpedPitch, 0, 0);
		BridgeRotateRoot.RelativeRotation = NewBridgeRotation;
		
		for(auto Wheel : WheelsToRotate)
		{
			FRotator WheelStartRotation = WheelStartRotations[Wheel];
			FRotator NewWheelRotation = WheelStartRotation + FRotator(WheelRotateDegreesMax * Pulley.PulleyAlpha, 0, 0);
			Wheel.ActorRotation = NewWheelRotation;
		}
	}

	UFUNCTION(CallInEditor)
	void SetTestActorRotationAndLocation()
	{
		TestBridgeRotateRoot.RelativeRotation = FRotator(MaxPitchAmount, 0, 0);
		TestBridgeForVFX.ActorLocation = TestBridgeRotateRoot.WorldLocation;
		TestBridgeForVFX.ActorRotation = TestBridgeRotateRoot.WorldRotation; 
	}
};