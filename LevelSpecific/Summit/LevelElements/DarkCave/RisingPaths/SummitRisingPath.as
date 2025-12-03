class ASummitRisingPath : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(EditAnywhere)
	float ZOffset = -3000;

	UPROPERTY(EditAnywhere)
	float Speed = 3500.0;

	float DelayTime;

	UPROPERTY()
	TSubclassOf<UCameraShakeBase> CameraShake;

	FVector TargetLoc;

	bool bPlayedInitialCamShake;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		TargetLoc = ActorLocation;
		ActorLocation += ActorUpVector * ZOffset;
		SetActorTickEnabled(false);
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		if (DelayTime > 0.0)
		{
			DelayTime -= DeltaSeconds;
			return;
		}
		else if (!bPlayedInitialCamShake)
		{
			bPlayedInitialCamShake = true;
			
			for (AHazePlayerCharacter Player : Game::Players)
			{
				Player.PlayWorldCameraShake(CameraShake, this, ActorLocation, 1500.0, 5000.0, 0.5);
			}
		}

		ActorLocation = Math::VInterpConstantTo(ActorLocation, TargetLoc, DeltaSeconds, Speed);
		if ((ActorLocation - TargetLoc).Size() <= 1.0)
		{
			FinishRise();
		}
	}

	void StartRise(float NewDelayTime)
	{
		SetActorTickEnabled(true);

		DelayTime = NewDelayTime;
	}

	void FinishRise()
	{
		for (AHazePlayerCharacter Player : Game::Players)
		{
			Player.PlayWorldCameraShake(CameraShake, this, ActorLocation, 3000.0, 10000.0, 1.0);
		}

		SetActorTickEnabled(false);
	}
};