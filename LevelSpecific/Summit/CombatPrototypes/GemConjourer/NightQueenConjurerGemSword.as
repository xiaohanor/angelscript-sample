class ANightQueenConjurerGemSword : ASummitNightQueenGem
{
	FVector StartLocation;
	AHazePlayerCharacter TargetPlayer;
	float MinStartAttackDist = 5.0;
	float AnticipationTime;
	float AnticipationDuration = 1.0;

	float AccelerateToStartSpeed = 1.5;
	float AttackMoveSpeed = 2200.0;
	float Speed;
	float AttackAcceleration = 1400.0;

	bool bIsAttacking;

	FHazeAcceleratedVector AccelVector;
	FHazeAcceleratedRotator AccelRot;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		Super::BeginPlay();
		AccelVector.SnapTo(ActorLocation);
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds) override
	{
		Super::Tick(DeltaSeconds);
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
	}

	void CheckForHits()
	{
		FHazeTraceDebugSettings DebugSettings;
		FHazeTraceSettings TraceSettings = Trace::InitChannel(ECollisionChannel::ECC_Visibility);
		TraceSettings.IgnoreActor(this);
		TraceSettings.UseLine();
		TraceSettings.DebugDraw(DebugSettings);

		FHitResult Hit = TraceSettings.QueryTraceSingle(ActorLocation, ActorLocation + ActorForwardVector * 300.0);

		if (Hit.bBlockingHit)
		{
			ASummitNightQueenGem OtherGem = Cast<ASummitNightQueenGem>(Hit.Actor);
			ANightQueenMetal OtherMetal = Cast<ANightQueenMetal>(Hit.Actor);

			if (OtherGem == nullptr && OtherMetal == nullptr)
				SetActorTickEnabled(false);
		}
	}
}