class AFlameAttackWave : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	USceneComponent SystemRoot;
	UPROPERTY(DefaultComponent, Attach = SystemRoot)
	UNiagaraComponent Fireball1;
	default Fireball1.bAutoActivate = false;
	UPROPERTY(DefaultComponent, Attach = SystemRoot)
	UNiagaraComponent Fireball2;
	default Fireball2.bAutoActivate = false;
	UPROPERTY(DefaultComponent, Attach = SystemRoot)
	UNiagaraComponent Fireball3;
	default Fireball3.bAutoActivate = false;
	UPROPERTY(DefaultComponent, Attach = SystemRoot)
	UNiagaraComponent Fireball4;
	default Fireball4.bAutoActivate = false;
	UPROPERTY(DefaultComponent, Attach = SystemRoot)
	UNiagaraComponent Fireball5;
	default Fireball5.bAutoActivate = false;
	UPROPERTY(DefaultComponent, Attach = SystemRoot)
	UNiagaraComponent Fireball6;
	default Fireball6.bAutoActivate = false;

	float Speed;

	FVector TargetLocation;

	TArray<UNiagaraComponent> SystemComponents;
	TArray<UActorComponent> ActorComps;

	float ActivateRate = 0.2;
	float ActivateTime;
	int Index;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		GetAllComponents(UNiagaraComponent, ActorComps);
		for (UActorComponent Comp : ActorComps)
		{
			UNiagaraComponent NewSystem = Cast<UNiagaraComponent>(Comp);

			if (NewSystem != nullptr)
				SystemComponents.Add(NewSystem);
		}
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		if (Time::GameTimeSeconds > ActivateTime && Index < SystemComponents.Num() - 1)
		{
			SystemComponents[Index].Activate();
			ActivateTime = Time::GameTimeSeconds + ActivateRate;
			Index++;
		}

		ActorLocation = Math::VInterpConstantTo(ActorLocation, TargetLocation, DeltaSeconds, Speed);

		float Dist = (ActorLocation - TargetLocation).Size();

		if (Dist < Speed * DeltaSeconds)
		{
			for (UNiagaraComponent System : SystemComponents)
			{
				System.Deactivate();
			}
			Timer::SetTimer(this, n"DelayedDestroy", 1.0, false);
			SetActorTickEnabled(false);
		}

		FHazeTraceDebugSettings DebugSettings;
		DebugSettings.TraceColor = FLinearColor::Red;
		DebugSettings.Thickness = 20.0;
		FHazeTraceSettings TraceSettings = Trace::InitChannel(ECollisionChannel::WeaponTraceEnemy);
		TraceSettings.UseBoxShape(FVector(1500.0, 1500.0, 5000.0));
		TraceSettings.DebugDraw(DebugSettings);

		FHitResultArray HitArray = TraceSettings.QueryTraceMulti(ActorLocation, ActorLocation + ActorForwardVector);

		for (FHitResult Hit : HitArray)
		{
			AHazePlayerCharacter Player = Cast<AHazePlayerCharacter>(Hit.Actor);

			if (Player != nullptr)
			{
				Player.KillPlayer();
			}
		}
	}

	UFUNCTION()
	void DelayedDestroy()
	{
		DestroyActor();
	}
}