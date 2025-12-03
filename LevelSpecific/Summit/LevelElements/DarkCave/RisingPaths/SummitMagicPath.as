class ASummitMagicPath : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	UStaticMeshComponent MeshComp;
	default MeshComp.SetCollisionEnabled(ECollisionEnabled::NoCollision);
	default MeshComp.SetHiddenInGame(true);

	UPROPERTY(DefaultComponent, Attach = Root)
	UDarkCaveGlowingSymbolsMeshComponent MovingMeshComp;

	UPROPERTY()
	TSubclassOf<UCameraShakeBase> CameraShake;

	float MoveSpeed = 5000.0;
	float RotateSpeed = 2.0;

	FVector StartLoc;
	FRotator StartRot;

	float DelayTime;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		SetActorTickEnabled(false);
		StartLoc = MovingMeshComp.WorldLocation;
		StartRot = MovingMeshComp.WorldRotation;
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		if (DelayTime > 0)
		{
			DelayTime -= DeltaSeconds;
			return;
		}

		MovingMeshComp.WorldLocation = Math::VInterpConstantTo(MovingMeshComp.WorldLocation, MeshComp.WorldLocation, DeltaSeconds, MoveSpeed);
		MovingMeshComp.WorldRotation = Math::RInterpConstantTo(MovingMeshComp.WorldRotation, MeshComp.WorldRotation, DeltaSeconds, MoveSpeed);

		if ((MovingMeshComp.WorldLocation - MeshComp.WorldLocation).Size() < 1.0)
		{
			for (AHazePlayerCharacter Player : Game::Players)
			{
				Player.PlayWorldCameraShake(CameraShake, this, ActorLocation, 2500.0, 8000.0, 0.5);
			}
			SetActorTickEnabled(false);
		}
		// else
		// {
		// 	MeshComp.WorldLocation = Math::VInterpConstantTo(MeshComp.WorldLocation, StartLoc, DeltaSeconds, MoveSpeed);
		// 	MeshComp.WorldRotation = Math::RInterpConstantTo(MeshComp.WorldRotation, StartRot, DeltaSeconds, MoveSpeed);
		// }
	}

	void ActivatePlatform(float NewDelayTime)
	{
		SetActorTickEnabled(true);
		DelayTime = NewDelayTime;
	}
};