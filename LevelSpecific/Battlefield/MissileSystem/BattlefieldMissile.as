struct FBattlefieldMissileParams
{
	UPROPERTY(EditDefaultsOnly)
	FVector Location;

	UPROPERTY(EditAnywhere)
	AActor TargetActor;

	UPROPERTY(EditAnywhere)
	float Speed = 12000.0;

	UPROPERTY(EditAnywhere)
	float DirectionAccelTime = 0.75;
}

class ABattlefieldMissile : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	UStaticMeshComponent MeshComp;

	UPROPERTY(DefaultComponent, Attach = Root)
	UNiagaraComponent System;

	ABattlefieldMissilePoolManager OwningManager;

	FBattlefieldMissileParams Params;

	AActor SpawningActor;

	float CurrentSpeed;

	FHazeAcceleratedVector AccelDir;

	bool bTriggeredImpact;

	FVector DirToTarget;

	float LifeTime = 7.0;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		SetActorTickEnabled(false);
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		//Homing Movement
		// DirToTarget = (Params.TargetActor.ActorLocation - ActorLocation).GetSafeNormal();
		AccelDir.AccelerateTo(DirToTarget, Params.DirectionAccelTime, DeltaSeconds);
		ActorLocation += AccelDir.Value * Params.Speed * DeltaSeconds;
		ActorRotation = AccelDir.Value.Rotation();

		//Trace for hits
		FHazeTraceSettings TraceSettings = Trace::InitChannel(ECollisionChannel::ECC_Visibility);
		TraceSettings.UseLine();
		TraceSettings.IgnoreActor(this);
		TraceSettings.IgnoreActor(SpawningActor);

		FVector End = ActorLocation + (AccelDir.Value * Params.Speed * DeltaSeconds);
		FHitResult Hit = TraceSettings.QueryTraceSingle(ActorLocation, End);

		if (Hit.bBlockingHit && !bTriggeredImpact)
		{
			bTriggeredImpact = true;
			
			FOnBattlefieldMissileImpactEffectParams EffectParams;
			EffectParams.Location = ActorLocation;
			UBattlefieldMissileEffectHandler::Trigger_MissileImpact(this, EffectParams);
			UBattlefieldMissileResponseComponent Response = UBattlefieldMissileResponseComponent::Get(Hit.Actor);
			
			if (Response != nullptr)
			{
				FBattleFieldMissileImpactResponseParams ResponseParams;
				ResponseParams.ImpactPoint = Hit.ImpactPoint;
				ResponseParams.ImpactDirection = ActorForwardVector;
				Response.TriggerMissileImpact(ResponseParams);
			}

			DeactivateMissile();

			// Timer::SetTimer(this, n"DelayedDeactivation", 1.5);
		}

		LifeTime -= DeltaSeconds;

		if (LifeTime <= 0.0)
		{
			DeactivateMissile();
		}
	}

	void ActivateMissile(FBattlefieldMissileParams MissileParams)
	{
		bTriggeredImpact = false;
		Params = MissileParams;
		AccelDir.SnapTo((Params.TargetActor.ActorLocation - ActorLocation).GetSafeNormal());
		SetActorTickEnabled(true);
		SetActorHiddenInGame(false);
	}

	UFUNCTION()
	void DelayedDeactivation()
	{
		DeactivateMissile();
	}

	void DeactivateMissile()
	{
		SetActorTickEnabled(false);
		SetActorHiddenInGame(true);
		OwningManager.DeactivateMissile(this);
	}
}