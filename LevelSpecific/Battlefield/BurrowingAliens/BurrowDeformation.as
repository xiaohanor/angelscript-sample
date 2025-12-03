class ABurrowDeformation : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	USceneComponent MeshRoot;

	UPROPERTY(EditAnywhere)
	ABurrowingAlien BurrowOwner;

	UPROPERTY(EditDefaultsOnly)
	FRuntimeFloatCurve MoveCurve;
	default MoveCurve.AddDefaultKey(0.0, 0.0);
	default MoveCurve.AddDefaultKey(1.0, 1.0);

	UPROPERTY(EditDefaultsOnly)
	FRuntimeFloatCurve RotateCurve;
	default RotateCurve.AddDefaultKey(0.0, 0.0);
	default RotateCurve.AddDefaultKey(1.0, 1.0);

	float CurrentDuration;
	float TotalDuration = 1.5;	
	float MinDuration = 1.4;
	float MaxDuration = 1.85;	

	float DelayTime;
	float MinDelay = 0.0;
	float MaxDelay = 0.25;

	FVector StartLoc;
	FVector EndLoc;
	FRotator StartRot;
	FRotator EndRot;

	float rInterpMin = 2.0;
	float rInterpMax = 2.5;
	float rInterp;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		SetActorTickEnabled(false);
		BurrowOwner.OnBurrowingAlienActivated.AddUFunction(this, n"OnBurrowingAlienActivated");

		EndLoc = ActorLocation;
		EndRot = ActorRotation;
		ActorLocation += FVector(0.0, 0.0, -1500.0);
		ActorRotation = FRotator(0.0, ActorRotation.Yaw, 0.0);
		StartLoc = ActorLocation;
		StartRot = ActorRotation;

		DelayTime = Math::RandRange(MinDelay, MaxDelay);
		TotalDuration = Math::RandRange(MinDuration, MaxDuration);
	}

	UFUNCTION()
	private void OnBurrowingAlienActivated()
	{
		ActivateDeformation();
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		if (DelayTime > 0.0)
		{
			DelayTime -= DeltaSeconds;
			return;
		}

		CurrentDuration += DeltaSeconds;
		float Alpha = Math::Clamp(CurrentDuration / TotalDuration, 0.0, 1.0);
		ActorLocation = Math::Lerp(StartLoc, EndLoc, MoveCurve.GetFloatValue(Alpha));
		ActorRotation = Math::LerpShortestPath(StartRot, EndRot, RotateCurve.GetFloatValue(Alpha));

		// ActorLocation = Math::VInterpTo(ActorLocation, EndLoc, DeltaSeconds, rInterp);
		// ActorRotation = Math::QInterpTo(ActorRotation.Quaternion(), EndRot.Quaternion(), DeltaSeconds, rInterp / 1.7).Rotator();
	}

	void ActivateDeformation()
	{
		SetActorTickEnabled(true);
	}
}