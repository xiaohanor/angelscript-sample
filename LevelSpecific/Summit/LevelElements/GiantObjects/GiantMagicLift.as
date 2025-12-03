class AGiantMagicLift : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	USceneComponent MeshRoot;

	UPROPERTY(DefaultComponent, Attach = Root)
	USceneComponent EndPoint;

	UPROPERTY(DefaultComponent, Attach = EndPoint)
	UBillboardComponent Visual;

	UPROPERTY(EditAnywhere)
	TArray<ANightQueenMetal> QueenMetal;

	UPROPERTY(EditAnywhere)
	AGiantHorn GiantHorn;

	UPROPERTY(EditAnywhere)
	float MaxMoveSpeed = 1400.0;
	float MinMoveSpeed = 400.0;
	float SpeedAcceleration = 300.0;
	float SpeedDecceleration = 500.0;
	float CurrentMoveSpeed;

	UPROPERTY()
	TSubclassOf<UCameraShakeBase> CameraShake;

	UPROPERTY()
	TSubclassOf<UCameraShakeBase> LoopingCameraShake;

	UCameraShakeBase CamShakeLoop1;
	UCameraShakeBase CamShakeLoop2;

	int MetalCount;
	bool bArrived;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		GiantHorn.OnGiantHornActivated.AddUFunction(this, n"OnGiantHornActivated");
		GiantHorn.AttachToComponent(MeshRoot, NAME_None, EAttachmentRule::KeepWorld, EAttachmentRule::KeepWorld, EAttachmentRule::KeepWorld, false);
		SetActorTickEnabled(false);

	if (QueenMetal.Num() > 0)	
		{
			for (ANightQueenMetal Metal : QueenMetal)
			{
				Metal.OnNightQueenMetalMelted.AddUFunction(this, n"OnMetalMelted");
				MetalCount++;
			}
		}

		CurrentMoveSpeed = MinMoveSpeed;
	}

	UFUNCTION()
	private void OnMetalMelted()
	{

			SetActorTickEnabled(true);
			Game::Mio.PlayCameraShake(CameraShake, this);
			Game::Zoe.PlayCameraShake(CameraShake, this);
			CamShakeLoop1 = Game::Mio.PlayCameraShake(LoopingCameraShake, this, 0.5);
			CamShakeLoop2 = Game::Zoe.PlayCameraShake(LoopingCameraShake, this, 0.5);
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		MeshRoot.RelativeLocation = Math::VInterpConstantTo(MeshRoot.RelativeLocation, EndPoint.RelativeLocation, DeltaSeconds, CurrentMoveSpeed);

		float Dist = (MeshRoot.RelativeLocation - EndPoint.RelativeLocation).Size();

		if (Dist < 2000.0)
		{
			CurrentMoveSpeed = Math::FInterpConstantTo(CurrentMoveSpeed, MinMoveSpeed, DeltaSeconds, SpeedDecceleration);
		}
		else
		{
			CurrentMoveSpeed = Math::FInterpConstantTo(CurrentMoveSpeed, MaxMoveSpeed, DeltaSeconds, SpeedAcceleration);
		}

		if (Dist < 5.0 && !bArrived)
		{
			bArrived = true;
			Game::Mio.PlayCameraShake(CameraShake, this);
			Game::Zoe.PlayCameraShake(CameraShake, this);
			Game::Mio.StopCameraShakeInstance(CamShakeLoop1);
			Game::Zoe.StopCameraShakeInstance(CamShakeLoop2);
		}
	}

	UFUNCTION()
	void OnGiantHornActivated()
	{
			SetActorTickEnabled(true);
			Game::Mio.PlayCameraShake(CameraShake, this);
			Game::Zoe.PlayCameraShake(CameraShake, this);
			CamShakeLoop1 = Game::Mio.PlayCameraShake(LoopingCameraShake, this, 0.5);
			CamShakeLoop2 = Game::Zoe.PlayCameraShake(LoopingCameraShake, this, 0.5);
	}
}