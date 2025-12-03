class ASkylineFlyingCarEnemyMissile : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	USceneComponent RotationPivot;

	UPROPERTY(DefaultComponent, Attach = RotationPivot)
	USceneComponent MeshRoot;

	UPROPERTY(DefaultComponent, Attach = MeshRoot)
	UStaticMeshComponent MeshComp;

	UPROPERTY(DefaultComponent)
	UBasicAIHealthComponent HealthComponent;
	default HealthComponent.SetMaxHealth(0.4);

	UPROPERTY(DefaultComponent)
	UHazeCapabilityComponent CapabilityComp;
	default CapabilityComp.DefaultCapabilities.Add(n"SkylineFlyingCarEnemyMissileLaunchCapability");
	default CapabilityComp.DefaultCapabilities.Add(n"SkylineFlyingCarEnemyMissileHomingCapability");
	default CapabilityComp.DefaultCapabilities.Add(n"SkylineFlyingCarEnemyMissileCloseInCapability");

	UPROPERTY(DefaultComponent,Attach = MeshRoot)
	USkylineFlyingCarRifleTargetableComponent RifleTargetableComponent;


	UPROPERTY(DefaultComponent, Attach = MeshRoot)
	USkylineFlyingCarBazookaTargetableComponent BazookaTargetableComponent;

	UPROPERTY(EditAnywhere, Meta = (ClampMin = 0.0, ClampMax = 1.0))
	float DamageAmount = 0.2;

	UPROPERTY(EditDefaultsOnly)
	TSubclassOf<UHazeUserWidget> WarningWidgetClass;

	UHazeUserWidget WarningWidget;

	UPROPERTY()
	UNiagaraSystem NiagaraExplosion;

	UPROPERTY(EditAnywhere)
	ASkylineFlyingCar FlyingCar;

	UPROPERTY(EditAnywhere)
	FVector Velocity;
	FVector ToTarget;
	UPROPERTY(EditAnywhere)
	float MinVelocity = 6600;
	UPROPERTY(EditAnywhere)
	float MaxVelocity = 13000;

	UPROPERTY(EditAnywhere)
	float HomingDelay = 0.65;
	float TimeToHome;
	bool bIsHoming = false;
	bool bIsClosingIn = false;


	float SpiralSpinSpeed;
	float CloseInDistance = 3600;

	float CurrentDistanceToTarget = BIG_NUMBER;


	FVector MeshRootOffset;
	FVector RotationPivotOffset;
	FVector StartHomingVelocity;
	float TimeSinceStartedHoming;


	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		HealthComponent.OnTakeDamage.AddUFunction(this, n"OnTakeDamage");

		TimeToHome = Time::GameTimeSeconds + HomingDelay;

		int RotationMultiplier = Math::RandRange(-3, 3);
		MeshRoot.AddLocalRotation(FRotator(0, 0, 45 * RotationMultiplier));

		SpiralSpinSpeed = Math::RandRange(75, 100);

		WarningWidget = Game::Mio.AddWidget(WarningWidgetClass);
		WarningWidget.AttachWidgetToActor(this);
		WarningWidget.AttachWidgetToComponent(MeshRoot);

		Timer::SetTimer(this, n"Explode", 5.0);
	}


	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		FVector StartLocation = MeshRoot.WorldLocation;
		ToTarget = FlyingCar.ActorLocation - ActorLocation;

		MeshComp.AddLocalRotation(FRotator(0, 180 * DeltaSeconds, 0));
		AddActorWorldOffset(Velocity * DeltaSeconds);


		//Do a spiral spin around the rotation pivot
		RotationPivot.AddRelativeRotation(FRotator(0, 0, SpiralSpinSpeed * DeltaSeconds));

		if(HasControl())
		{
			if(ToTarget.Size() < 750)
				CrumbImpactWithCar();
		}


		if(bIsHoming)
		{
			float Alpha = Math::Clamp(ToTarget.Size() / CloseInDistance, 0, 1);
			RotationPivot.RelativeLocation = RotationPivotOffset * Alpha;
			MeshRoot.RelativeLocation = MeshRootOffset * Alpha;
		}

		if(GameTimeSinceCreation > 10.0)
		{
			Explode();
		}

		


		MeshRoot.WorldRotation = (MeshRoot.WorldLocation - StartLocation).Rotation();
	}

	UFUNCTION(CrumbFunction)
	void CrumbImpactWithCar()
	{
		FSkylineFlyingCarDamage CarDamage;
		CarDamage.Amount = DamageAmount;
		FlyingCar.TakeDamage(CarDamage);

		Explode();
	}

	UFUNCTION()
	private void OnTakeDamage(AHazeActor ActorTakingDamage, AHazeActor Attacker, float Damage,
	                          EDamageType DamageType)
	{
		if (HealthComponent.IsDead())
		{
			Explode();
		}
	}

	UFUNCTION()
	void TimeToDestroy()
	{
		Explode();
	}

	UFUNCTION()
	void Explode()
	{
		if(WarningWidget != nullptr)
		{
			Game::Mio.RemoveWidget(WarningWidget);
			WarningWidget = nullptr;
		}

		Niagara::SpawnOneShotNiagaraSystemAtLocation(NiagaraExplosion, MeshRoot.WorldLocation);
		USkylineFlyingCarEnemyMissileEventHandler::Trigger_Explode(Game::Zoe, FSkylineEnemyMissileEventData(this));
		TriggerExplosionAudio();

		DestroyActor();
	}

	UFUNCTION(BlueprintEvent)
	void TriggerExplosionAudio(){}

}