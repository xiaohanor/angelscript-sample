class ABattlefieldTank : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	USceneComponent TankRoot;
	UPROPERTY(DefaultComponent, Attach = TankRoot)
	UStaticMeshComponent TankBase;
	UPROPERTY(DefaultComponent, Attach = TankBase)
	UStaticMeshComponent TankTurret;
	UPROPERTY(DefaultComponent, Attach = TankTurret)
	UStaticMeshComponent TankBarrel;
	UPROPERTY(DefaultComponent, Attach = TankTurret)
	USceneComponent ShootOrigin;
	UPROPERTY(DefaultComponent, Attach = TankTurret)
	USceneComponent ShootOrigin2;
	UPROPERTY(DefaultComponent, Attach = TankBarrel)
	USceneComponent SoundOriginComp;

	UPROPERTY(DefaultComponent, Attach = TankTurret)
	UNiagaraComponent MuzzleFlash;
	default MuzzleFlash.SetAutoActivate(false);
	UPROPERTY(DefaultComponent, Attach = TankTurret)
	UNiagaraComponent MuzzleFlash2;
	default MuzzleFlash2.SetAutoActivate(false);

	UPROPERTY(DefaultComponent, Attach = Root)
	USceneComponent DestroyedRoot;
	UPROPERTY(DefaultComponent, Attach = DestroyedRoot)
	UStaticMeshComponent DestroyedTank;
	default DestroyedTank.SetHiddenInGame(true);

	UPROPERTY(DefaultComponent, Attach = Root)
	UNiagaraComponent ExplosionComp;
	default ExplosionComp.SetAutoActivate(false);

	UPROPERTY(DefaultComponent, Attach = Root)
	UNiagaraComponent SteamComp;
	default SteamComp.SetAutoActivate(false);

	UPROPERTY(DefaultComponent)
	UBattlefieldLaserResponseComponent LaserResponseComp;

	float FireRate = 5.0;
	float FireTime;
	float DelayFireTime;

	UPROPERTY()
	TSubclassOf<ABattlefieldTankProjectile> ProjectileClass;

	UPROPERTY()
	TSubclassOf<UCameraShakeBase> CameraShake;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		DelayFireTime = Math::RandRange(0.0, FireRate);
		LaserResponseComp.OnBattlefieldLaserImpact.AddUFunction(this, n"OnBattlefieldLaserImpact");
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		if (DelayFireTime > 0.0)
		{
			DelayFireTime -= DeltaSeconds;
			return;
		}

		if (Time::GameTimeSeconds > FireTime)
		{
			FireTime = Time::GameTimeSeconds + FireRate;
			SpawnActor(ProjectileClass, ShootOrigin.WorldLocation, ShootOrigin.WorldRotation);
			SpawnActor(ProjectileClass, ShootOrigin2.WorldLocation, ShootOrigin2.WorldRotation);
			UBattlefieldTankEffectHandler::Trigger_OnTankFired(this, FBattlefieldTankFiredParams(SoundOriginComp.WorldLocation));
			MuzzleFlash.Activate();
			MuzzleFlash2.Activate();
		}
	}

	UFUNCTION()
	private void OnBattlefieldLaserImpact()
	{
		TankBase.SetHiddenInGame(true);
		TankTurret.SetHiddenInGame(true);
		TankBarrel.SetHiddenInGame(true);
		TankBase.SetCollisionEnabled(ECollisionEnabled::NoCollision);
		TankTurret.SetCollisionEnabled(ECollisionEnabled::NoCollision);
		TankBarrel.SetCollisionEnabled(ECollisionEnabled::NoCollision);

		DestroyedTank.SetHiddenInGame(false);
		DestroyedTank.SetCollisionEnabled(ECollisionEnabled::QueryAndPhysics);

		ExplosionComp.Activate();
		SteamComp.Activate();

		OnExploded();

		for (AHazePlayerCharacter Player : Game::Players)
		{
			Player.PlayWorldCameraShake(CameraShake, this, ActorLocation, 8000.0, 20000.0);
		}

		SetActorTickEnabled(false);
	}

	UFUNCTION(BlueprintEvent)
	void OnExploded() {}
};