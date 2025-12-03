class ASolarFlareActivatableOpening : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	USceneComponent RotateRoot1;

	UPROPERTY(DefaultComponent, Attach = Root)
	USceneComponent RotateRoot2;

	bool bOpen;

	FRotator StartRot;

	float InterpSpeed;
	float InterpSpeedStart = 5.0;
	float InterpSpeedTarget = 15.0;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		StartRot = RotateRoot1.RelativeRotation;
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		InterpSpeed = Math::FInterpConstantTo(InterpSpeed, InterpSpeedTarget, DeltaSeconds, InterpSpeedStart);

		if (bOpen)
		{
			RotateRoot1.RelativeRotation = Math::QInterpConstantTo(RotateRoot1.RelativeRotation.Quaternion(), FRotator(90, 0, 0).Quaternion(), DeltaSeconds, InterpSpeed).Rotator();
			RotateRoot2.RelativeRotation = Math::QInterpConstantTo(RotateRoot2.RelativeRotation.Quaternion(), FRotator(-90, 0, 0).Quaternion(), DeltaSeconds, InterpSpeed).Rotator();
		}
		else
		{
			RotateRoot1.RelativeRotation = Math::QInterpConstantTo(RotateRoot1.RelativeRotation.Quaternion(), StartRot.Quaternion(), DeltaSeconds, InterpSpeed).Rotator();
			RotateRoot2.RelativeRotation = Math::QInterpConstantTo(RotateRoot2.RelativeRotation.Quaternion(), StartRot.Quaternion(), DeltaSeconds, InterpSpeed).Rotator();
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