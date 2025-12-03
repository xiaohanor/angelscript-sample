class AMeltdownBossPhaseTwoMeteorPool : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent)
	USceneComponent AsteroidRoot;

	UPROPERTY(DefaultComponent, Attach = AsteroidRoot)
	UStaticMeshComponent Asteroid;
	default Asteroid.SetHiddenInGame(true);
	default Asteroid.SetCollisionEnabled(ECollisionEnabled::NoCollision);
	
	UPROPERTY(DefaultComponent)
	USceneComponent PoolCue;

	UPROPERTY(DefaultComponent, Attach = AsteroidRoot)
	UBillboardComponent FireSpawn;

	UPROPERTY(DefaultComponent)
	UMeltdownGlitchShootingResponseComponent ShootComp;

	UPROPERTY(DefaultComponent, Attach = AsteroidRoot)
	UHazeSphereCollisionComponent AsteroidCollision;

	AHazePlayerCharacter Player;

	UPROPERTY(EditAnywhere)
	AMeltdownBossPhaseTwoFlyingCube FlyingAsteroid;

	UPROPERTY()
	bool bIsDisabled;

	UPROPERTY()
	FVector StartingLoc;

	UPROPERTY()
	FVector AsteroidRootLocation;

	FVector TargetLoc;

	FVector MissileSpawnLocation;

	UPROPERTY()
	FRotator AsteroidRot;

	UPROPERTY()
	FRotator AsteroidRotFast;

	FRotator StartRot;

	UPROPERTY(EditAnywhere)
	int Health;
	
	float Speed = 2500;

	float Timer = 0.0;
	float LifeTime = 5.0;

	float FireRate = 0.1;

	float TimeToFire;

	UPROPERTY()
	bool bCanFire;

	UPROPERTY()
	bool bHasLanded;

	UPROPERTY()
	bool bShouldTrace;

	UPROPERTY(EditAnywhere)
	TSubclassOf<AMeltdownBossPhaseTwoFireTrail> Trail;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{	
		SetActorTickEnabled(false);
		AddActorDisable(this);
		Player = Game::GetClosestPlayer(ActorLocation);
		AsteroidRot = FRotator(-3.0,0.0,0.0);
		AsteroidRotFast = FRotator(-10.0,0.0,0.0);
		StartingLoc = ActorLocation;
		AsteroidRootLocation = AsteroidRoot.WorldLocation;

		AsteroidCollision.OnComponentBeginOverlap.AddUFunction(this, n"OnDamageOverlap");
		ShootComp.OnGlitchHit.AddUFunction(this, n"GlitchHit");
	}

	UFUNCTION(BlueprintCallable)
	void OrientToTarget()
	{
		SetActorTickEnabled(true);
		RemoveActorDisable(this);
		bShouldTrace = true;
		TargetLoc = Player.ActorLocation;
		FVector Totarget = (TargetLoc - ActorLocation).GetSafeNormal().ConstrainToPlane(FVector::UpVector);
		FQuat TargetRot = Totarget.ToOrientationQuat();
		SetActorRotation(TargetRot);
		UMeltdownBossPhaseTwoMeteorPoolEventHandler::Trigger_BatImpact(this, FMeltdownBossPhaseTwoMeteorPoolEventHandlerData(Asteroid));
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		FVector Velocity = ActorForwardVector * Speed;
		FVector DeltaMove = Velocity * DeltaSeconds;

		Timer += DeltaSeconds;
		if (Timer > LifeTime)
		{
			AddActorDisable(this);
			DestroyAsteroid();
			bHasLanded = false;
			Timer = 0.0;
		}

		MoveMissile(DeltaMove);

			if(TimeToFire > Time::GameTimeSeconds)
			return;
			
			if(bCanFire == true)
			{
			TimeToFire = Time::GameTimeSeconds + FireRate;
			SpawnFireTrail();
			Speed = 2050;
			}
	}

	void MoveMissile(FVector DeltaMove)
	{
			AsteroidRoot.WorldLocation += DeltaMove;
			Asteroid.AddLocalRotation(AsteroidRot);
			if(bCanFire == true)
			Asteroid.AddLocalRotation(AsteroidRotFast);

	}

	UFUNCTION()
	private void OnDamageOverlap(UPrimitiveComponent OverlappedComponent, AActor OtherActor,
	                             UPrimitiveComponent OtherComp, int OtherBodyIndex, bool bFromSweep,
	                             const FHitResult&in SweepResult)
	{
		AHazePlayerCharacter DamagedPlayer = Cast<AHazePlayerCharacter>(OtherActor);

		if(DamagedPlayer == nullptr)
			return;

		DamagedPlayer.DamagePlayerHealth(0.5);
	}

	void SpawnFireTrail()
	{	
		MissileSpawnLocation = FireSpawn.WorldLocation;
		AMeltdownBossPhaseTwoFireTrail MissileSpawned = Cast<AMeltdownBossPhaseTwoFireTrail> (SpawnActor(Trail, MissileSpawnLocation, FireSpawn.WorldRotation, bDeferredSpawn = true));
		FinishSpawningActor(MissileSpawned);
	}

	UFUNCTION()
	private void GlitchHit(FMeltdownGlitchImpact Impact)
	{
		Health -= 1;

		Print("" + Health, 1.0);

		if(Health <= 0)
		{
			DestroyAsteroid();
			bCanFire = false;

			Health = 4;
			
			UMeltdownBossPhaseTwoMeteorPoolEventHandler::Trigger_AsteroidDestroyed(this,FMeltdownBossPhaseTwoMeteorPoolEventHandlerData(Asteroid));
		}

	}

	UFUNCTION(BlueprintCallable)
	void ActivateImpact()
	{
		UMeltdownBossPhaseTwoMeteorPoolEventHandler::Trigger_GroundImpact(this, FMeltdownBossPhaseTwoMeteorPoolEventHandlerData(Asteroid));
	}

	UFUNCTION()
	void DestroyAsteroid()
	{
		ActorLocation = StartingLoc;
		AsteroidRoot.WorldLocation = AsteroidRootLocation;
		SetActorTickEnabled(true);
		AddActorDisable(this);
	}

	UFUNCTION(BlueprintCallable)
	void ResetAsteroid()
	{
		bIsDisabled = false;
	}
};