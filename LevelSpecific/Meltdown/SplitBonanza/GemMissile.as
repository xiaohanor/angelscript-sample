class AGemMissile : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	USceneComponent MeshRoot;

	UPROPERTY()
	UNiagaraSystem ExplosionSystem;

	UPROPERTY()
	float HitDistanceCheck = 300.0;

	FVector StartLocation;
	AHazePlayerCharacter TargetPlayer;
	float MinStartAttackDist = 5.0;
	float AnticipationTime;
	float AnticipationDuration = 1.0;

	float AccelerateToStartSpeed = 1.5;
	float AttackMoveSpeed = 1000.0;
	float Speed;
	float AttackAcceleration = 500.0;

	bool bIsAttacking;

	float LifeTime = 10.0;

	FHazeAcceleratedVector AccelVector;
	FHazeAcceleratedRotator AccelRot;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		AccelVector.SnapTo(ActorLocation);
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		if (bIsAttacking)
		{
			if (Time::GameTimeSeconds > AnticipationTime)
			{
				Speed = Math::FInterpConstantTo(Speed, AttackMoveSpeed, DeltaSeconds, AttackAcceleration);
				ActorLocation += ActorForwardVector * Speed * DeltaSeconds;
			}
			else
			{
				AccelRot.AccelerateTo((TargetPlayer.ActorLocation - ActorLocation).Rotation(), 0.5, DeltaSeconds);
				ActorRotation = AccelRot.Value;
			}
		}
		else
		{
			AccelVector.AccelerateTo(StartLocation, AccelerateToStartSpeed, DeltaSeconds);
			ActorLocation = AccelVector.Value;
			ActorRotation = AccelVector.Value.Rotation();
			AccelRot.SnapTo(ActorRotation);
			float Dist = (ActorLocation - StartLocation).Size();
			if (Dist < MinStartAttackDist)
			{
				bIsAttacking = true;
				AnticipationTime = Time::GameTimeSeconds + AnticipationDuration;
			}	
		}

		CheckForHits();

		LifeTime -= DeltaSeconds;

		if (LifeTime <= 0.0)
			DestroyActor(); 
	}

	void CheckForHits()
	{
		FHazeTraceDebugSettings DebugSettings;
		FHazeTraceSettings TraceSettings = Trace::InitChannel(ECollisionChannel::EnemyCharacter);
		TraceSettings.IgnoreActor(this);
		TraceSettings.UseLine();
		TraceSettings.DebugDraw(DebugSettings);

		FHitResult Hit = TraceSettings.QueryTraceSingle(ActorLocation, ActorLocation + ActorForwardVector * HitDistanceCheck);

		if (Hit.bBlockingHit)
		{

				AHazePlayerCharacter Player = Cast<AHazePlayerCharacter>(Hit.Actor);

				if (Player != nullptr)
				{
					Player.DamagePlayerHealth(0.1);
				}

				Niagara::SpawnOneShotNiagaraSystemAtLocation(ExplosionSystem, ActorLocation, ActorRotation);
				DestroyActor();
			
		}
	}
}