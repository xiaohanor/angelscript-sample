class ASolarFlareActivatablePump : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	USceneComponent PumpRoot;

	FVector TargetLoc;
	FVector StartLoc;

	bool bOpen;

	float InterpSpeed;
	float InterpSpeedStart = 50.0;
	float InterpSpeedTarget = 150.0;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		TargetLoc = PumpRoot.RelativeLocation + FVector(0,0,500.0);
		StartLoc = PumpRoot.RelativeLocation;
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		InterpSpeed = Math::FInterpConstantTo(InterpSpeed, InterpSpeedTarget, DeltaSeconds, InterpSpeedStart);
		
		if (bOpen)
		{
			PumpRoot.RelativeLocation = Math::VInterpConstantTo(PumpRoot.RelativeLocation, TargetLoc, DeltaSeconds, InterpSpeed);
		}
		else
		{
			PumpRoot.RelativeLocation = Math::VInterpConstantTo(PumpRoot.RelativeLocation, StartLoc, DeltaSeconds, InterpSpeed);
		}
	}

	void Open()
	{
		InterpSpeed = InterpSpeedStart;
		bOpen = true;
	}

	void Close()
	{
		InterpSpeed = InterpSpeedStart;
		bOpen = false;
	}
};