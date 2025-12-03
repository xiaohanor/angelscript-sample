class AMeltdownBossPhaseTwoTornado : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent)
	USceneComponent MeshRoot;

	UPROPERTY(DefaultComponent, Attach = MeshRoot)
	UStaticMeshComponent Tornado;

	UPROPERTY(DefaultComponent, Attach = MeshRoot)
	UDeathTriggerComponent KillTrigger;
	default KillTrigger.Shape = FHazeShapeSettings::MakeBox(FVector(200, 200, 2000));
	default KillTrigger.RelativeLocation = FVector(0, 0, 2000);
	
	AHazeActor TargetPlayer; 

	float MinSpeed = 1000;
	float MaxSpeed = 1750;
	float TurnSpeed = 180;
	float Acceleration = 1200;

	float LockOnDistance = 2000.0;

	UPROPERTY(EditAnywhere)
	bool bTargetMio;
	UPROPERTY(EditAnywhere)
	bool bTargetZoe;

	FHazeTimeLike TornadoScale;
	default TornadoScale.Duration = 2.0;
	default TornadoScale.UseSmoothCurveZeroToOne();

	FVector StartScale = FVector(0,0,0);
	FVector EndScale = FVector(0.5,0.5,0.5);

	float CurrentLifeTime = 0.0;
	float LifeTime = 15.0;

	FVector Velocity;
	FVector TargetDirection;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		AddActorDisable(this);

		if(bTargetMio == true)
			TargetPlayer = Game::Mio;
		if(bTargetZoe == true)
			TargetPlayer = Game::Zoe;

		TornadoScale.BindUpdate(this, n"ScaleUpdate");
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		float Speed = Velocity.Size();
		Speed = Math::FInterpConstantTo(Speed, MaxSpeed, DeltaSeconds, Acceleration);
		Speed = Math::Clamp(Speed, MinSpeed, MaxSpeed);

		FVector Direction = Velocity.GetSafeNormal();

		// Don't allow turning if we're too close to the player
		if (TargetPlayer.ActorLocation.Dist2D(ActorLocation) > LockOnDistance || TargetDirection.IsNearlyZero())
		{
			TargetDirection = (TargetPlayer.ActorLocation - ActorLocation);
			TargetDirection = TargetDirection.ConstrainToPlane(FVector::UpVector).GetSafeNormal();
		}

		if (Direction.IsNearlyZero())
			Direction = TargetDirection;

		Direction = Math::VInterpNormalRotationTo(
			Direction, TargetDirection, DeltaSeconds, TurnSpeed
		);

		Velocity = Direction * Speed;
		ActorLocation = ActorLocation + Velocity * DeltaSeconds;

		CurrentLifeTime += DeltaSeconds;
		if (CurrentLifeTime >= LifeTime)
			AddActorDisable(this);
	}

	UFUNCTION(BlueprintCallable, DevFunction)
	void StartTornado()
	{
		CurrentLifeTime = 0.0;
		TornadoScale.Play();
		RemoveActorDisable(this);
	}

	UFUNCTION()
	private void ScaleUpdate(float CurrentValue)
	{
		Tornado.SetRelativeScale3D(Math::Lerp(StartScale, EndScale, CurrentValue));
	}
};