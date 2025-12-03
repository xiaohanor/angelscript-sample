class ATreasureTempleGemTrap : ASummitNightQueenGem
{
	UPROPERTY(DefaultComponent, Attach = Root)
	UNiagaraComponent Effect;

	TArray<UStaticMeshComponent> MeshComps;

	float Speed = 1500.0;

	FVector TargetDirection;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		Super::BeginPlay();
		MeshComp.SetHiddenInGame(true);
		CapsuleComp.SetCollisionEnabled(ECollisionEnabled::NoCollision);
		GetComponentsByClass(MeshComps);
		
		for (UStaticMeshComponent Mesh : MeshComps)
			Mesh.SetHiddenInGame(true);
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		Super::Tick(DeltaSeconds);
		float DeltaSpeed = Speed * DeltaSeconds;
		ActorLocation += TargetDirection * DeltaSpeed;

		FHazeTraceSettings TraceSettings = Trace::InitChannel(ECollisionChannel::WeaponTraceEnemy);
		TraceSettings.UseLine();
		FHitResult Hit = TraceSettings.QueryTraceSingle(ActorLocation, ActorLocation + TargetDirection * (Speed * DeltaSeconds));

		if (Hit.bBlockingHit)
		{
			ImpactGem(DeltaSpeed);
			SetActorTickEnabled(false);
		}
	}

	void ImpactGem(float DeltaSpeed)
	{
		FHazeTraceDebugSettings DebugSettings;
		DebugSettings.TraceColor = FLinearColor::Red;
		DebugSettings.Thickness = 20.0;
		FHazeTraceSettings TraceSettings = Trace::InitChannel(ECollisionChannel::WeaponTraceEnemy);
		TraceSettings.UseSphereShape(700.0);
		TraceSettings.DebugDraw(DebugSettings);

		FHitResultArray HitArray = TraceSettings.QueryTraceMulti(ActorLocation, ActorLocation + ActorForwardVector);


		for (FHitResult Hit : HitArray)
		{
			// Debug::DrawDebugSphere(Hit.Actor.ActorLocation, 300.0, 16, FLinearColor::Red, 15, 10.0);

			AHazePlayerCharacter Player = Cast<AHazePlayerCharacter>(Hit.Actor);
			
			if (Player != nullptr)
			{
				Player.DamagePlayerHealth(0.2);

				FTeenDragonStumble Stumble;
				Stumble.Duration = 1;
				Stumble.Move = (Player.ActorLocation - ActorLocation).GetSafeNormal() * 1100;
				Stumble.Apply(Player);
				Player.SetActorRotation((-Stumble.Move).ToOrientationQuat());
			}
		}

		for (UStaticMeshComponent Mesh : MeshComps)
			Mesh.SetHiddenInGame(false);

		// FOnGemTrapImpactParams Params;
		// Params.Location = ActorLocation;
		// UTreasureTempleGemTrapEffectHandler::Trigger_OnGemImpact(this, Params);

		// FOnSummitGemDestroyedParams DestroyParams;
		// DestroyParams.Location = ActorLocation;
		// DestroyParams.Rotation = ActorRotation;
		// DestroyParams.Scale = DestructionEffectScale;
		// USummitGemDestructionEffectHandler::Trigger_DestroyGem(this, DestroyParams);

		FOnGemTrapImpactParams Params;
		Params.Location = ActorLocation;
		UTreasureTempleGemTrapEffectHandler::Trigger_OnGemImpact(this, Params);
		UTreasureTempleGemTrapEffectHandler::Trigger_OnGemTelegraphFinish(this);

		Timer::SetTimer(this, n"DelayCollisionSet", 0.8);

		Game::Mio.PlayCameraShake(CameraShake, this, 0.5);
		Game::Zoe.PlayCameraShake(CameraShake, this, 0.5);

		Effect.Deactivate();
	}

	void SetTelegraphMode(FVector TargetLocation)
	{
		FOnGemTrapTelegraphParams Params;
		Params.Location = TargetLocation;
		UTreasureTempleGemTrapEffectHandler::Trigger_OnGemTelegraphStart(this, Params);
	}

	//TEMP - use tick later to check when they leave outside of the capsule bounds
	UFUNCTION()
	void DelayCollisionSet()
	{
		CapsuleComp.SetCollisionEnabled(ECollisionEnabled::QueryAndPhysics);

	}
}