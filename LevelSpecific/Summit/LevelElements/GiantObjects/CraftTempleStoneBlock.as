class ACraftTempleStoneBlock : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	USceneComponent RotationComp;

	UPROPERTY(EditAnywhere)
	TArray<AActor> AttachActors;

	UPROPERTY(EditAnywhere)
	TArray<ANightQueenMetal> NightQueenMetal;

	UPROPERTY(EditAnywhere, Category = "Settings")
	float PitchTarget = -112.5;

	UPROPERTY(EditAnywhere, Category = "Settings")
	float Bounciness = 0.5;

	UPROPERTY(EditAnywhere, Category = "Settings")
	float MinRotationSpeed = 0.5;

	UPROPERTY(EditAnywhere, Category = "Settings")
	float MaxRotationForce = 50.0;

	UPROPERTY(EditAnywhere, Category = "Settings")
	float AccelerationSpeed = 60.0;

	int Count;
	int MaxCount;

	FRotator StartRot;
	float RotationForce;
	float CurrentPitch;


	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		SetActorTickEnabled(false);

		for (AActor Actor : AttachActors)
		{
			Actor.AttachToComponent(RotationComp, NAME_None, EAttachmentRule::KeepWorld, EAttachmentRule::KeepWorld, EAttachmentRule::KeepWorld, false);
		}

		for (ANightQueenMetal Metal : NightQueenMetal)
		{
			Metal.OnNightQueenMetalMelted.AddUFunction(this, n"OnNightQueenMetalMelted");
		}

		MaxCount = NightQueenMetal.Num();
		StartRot = RotationComp.RelativeRotation;
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		RotationForce = Math::FInterpConstantTo(RotationForce, MaxRotationForce, DeltaSeconds, AccelerationSpeed);
		CurrentPitch -= RotationForce * DeltaSeconds;
		RotationComp.RelativeRotation = StartRot + FRotator(CurrentPitch, 0.0, 0.0);	
		
		if (CurrentPitch <= PitchTarget)
		{
			if (Math::Abs(RotationForce) < MinRotationSpeed)
			{
				RotationForce = 0.0;
				SetActorTickEnabled(false);
			}
			else
			{
				RotationForce = -RotationForce * Bounciness;
			}
		}
	}

	UFUNCTION()
	private void OnNightQueenMetalMelted()
	{
		Count++;

		if (Count >= MaxCount)
			SetActorTickEnabled(true);
	}
}