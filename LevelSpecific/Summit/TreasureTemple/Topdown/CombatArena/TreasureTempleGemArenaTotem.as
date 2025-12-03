class ATreasureTempleGemArenaTotem : ASummitNightQueenGem
{
	default bPlayDefaultDestroyEffect = false;

	UPROPERTY(DefaultComponent, Attach = MeshComp)
	USceneComponent ShootOrigin;

	UPROPERTY(DefaultComponent)
	UTeenDragonAcidAutoAimComponent AutoAimComp;

	UPROPERTY(EditAnywhere)
	bool bDisableOnStart = true;

	UPROPERTY(EditAnywhere)
	bool bAlwaysRotating = true;

	UPROPERTY()
	TSubclassOf<ATreasureTempleArenaTotemMetalCover> MetalClass;

	ATreasureTempleArenaTotemMetalCover MetalCover;

	UPROPERTY()
	TSubclassOf<AGemSpearAttack> GemSpearClass;

	float FireRate = 0.5;
	float FireTime;

	float DelayAttackTime = 1.5;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		Super::BeginPlay();

		if (bDisableOnStart)
		{
			SetActorTickEnabled(false);
			SetActorHiddenInGame(true);
			CapsuleComp.SetCollisionEnabled(ECollisionEnabled::NoCollision);
		}

		MetalCover = SpawnActor(MetalClass, ActorLocation, ActorRotation, bDeferredSpawn = true);
		MetalCover.AttachToComponent(MeshComp, NAME_None, EAttachmentRule::KeepWorld, EAttachmentRule::KeepWorld, EAttachmentRule::KeepWorld, false);
		MetalCover.AddPoweringCrystal(this);
		MetalCover.AddActorDisable(this);
		PoweringMetalPieces.Add(MetalCover);
		MetalCover.MakeNetworked(this);
		FinishSpawningActor(MetalCover);

		FHazeTraceDebugSettings DebugSettings;
		DebugSettings.TraceColor = FLinearColor::Red;
		DebugSettings.Thickness = 20.0;
		FHazeTraceSettings TraceSettings = Trace::InitChannel(ECollisionChannel::WeaponTraceEnemy);
		TraceSettings.UseSphereShape(500.0);
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

		OnSummitGemDestroyed.AddUFunction(this, n"OnSummitGemDestroyed");
	}

	UFUNCTION()
	private void OnSummitGemDestroyed(ASummitNightQueenGem CrystalDestroyed)
	{
		FOnGemTotemDestroyedParams Params;
		Params.Location = ActorLocation;
		UTreasureTempleGemArenaTotemEffectHandler::Trigger_OnGemTotemDestroyed(this, Params);		
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		Super::Tick(DeltaSeconds);
		
		if (Time::GameTimeSeconds < DelayAttackTime)
			return;

		if (Time::GameTimeSeconds > FireTime)
		{
			FireTime = Time::GameTimeSeconds + FireRate;
			AGemSpearAttack Spear = SpawnActor(GemSpearClass, ShootOrigin.WorldLocation, ShootOrigin.WorldRotation, bDeferredSpawn = true);
			Spear.bIsAttacking = true;
			Spear.AttackMoveSpeed = 1700.0;
			FinishSpawningActor(Spear);

			FOnGemTotemFireParams Params;
			Params.Location = ShootOrigin.WorldLocation;
			UTreasureTempleGemArenaTotemEffectHandler::Trigger_OnGemTotemFire(this, Params);
		}

		if (bAlwaysRotating)
			MeshComp.AddLocalRotation(FRotator(0.0, 45.0, 0.0) * DeltaSeconds);
	}

	UFUNCTION()
	void ActivateTotem()
	{
		SetActorTickEnabled(true);
		SetActorHiddenInGame(false);
		CapsuleComp.SetCollisionEnabled(ECollisionEnabled::QueryAndPhysics);
		DelayAttackTime += Time::GameTimeSeconds;
		MetalCover.RemoveActorDisable(this);

		FOnGemTotemInitiateParams Params;
		Params.Location = ActorLocation;
		UTreasureTempleGemArenaTotemEffectHandler::Trigger_OnGemTotemInitiate(this, Params);
	}
}