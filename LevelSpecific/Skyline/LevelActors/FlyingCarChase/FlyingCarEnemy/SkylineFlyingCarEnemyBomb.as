class ASkylineFlyingCarEnemyBomb : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent)
	USceneComponent MeshRoot;

	UPROPERTY(DefaultComponent, Attach = MeshRoot)
	UStaticMeshComponent MeshComp;

	UPROPERTY(DefaultComponent)
	UStaticMeshComponent DetectionField;

	UPROPERTY(DefaultComponent, Attach = MeshRoot)
	USkylineFlyingCarRifleTargetableComponent RifleTargetableComponent;

	UPROPERTY(DefaultComponent, Attach = MeshRoot)
	USkylineFlyingCarBazookaTargetableComponent BazookaTargetableComponent;

	UPROPERTY(DefaultComponent, Attach = MeshRoot)
	USphereComponent Collision;


	UPROPERTY(DefaultComponent)
	USphereComponent TriggerBox;

	UPROPERTY(DefaultComponent)
	UBasicAIHealthComponent HealthComp;

	UPROPERTY(EditDefaultsOnly)
	TSubclassOf<UHazeUserWidget> WarningWidgetClass;

	UHazeUserWidget WarningWidget;


	UPROPERTY()
	UNiagaraSystem ExplosionNiagara;

	UPROPERTY(EditDefaultsOnly)
	TSubclassOf<ASkylineFlyingCarEnemy> BomberClass;


	UPROPERTY(EditAnywhere, Meta = (ClampMin = 0.0, ClampMax = 1.0))
	float DamageAmount = 0.3;


	FSplinePosition SplinePosition;
	FVector OffsetFromSpline;

	UPROPERTY(EditAnywhere)
	ASkylineFlyingHighway Highway;

	UPROPERTY(EditAnywhere)
	AActorTrigger Trigger;

	ASkylineFlyingCar Car;


	bool bTargetDetected;
	bool bActivated = false;
	// float ActivationDistance = 18000;

	float Offset = 1750;
	float SplineSpeed = 1500;
	float HighwaySplineSpeed = 2200;
	float HomingSpeed = 4;
	float DetectionFieldScale;
	float DetectionFieldTargetScale;


	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		// Root.SetHiddenInGame(true, true);
		HealthComp.OnTakeDamage.AddUFunction(this, n"OnTakeDamage");
		TriggerBox.OnComponentBeginOverlap.AddUFunction(this, n"OnTriggerBeginOverlap");

		// Eman TODO: Who the hell is shooting nullptr bombs?!
		if (Trigger != nullptr)
			Trigger.OnActorEnter.AddUFunction(this, n"OnActorEnter");

		DetectionFieldScale = DetectionField.WorldScale.X;
		DetectionFieldTargetScale = DetectionFieldScale;

		if(Highway.MovementConstraintType == ESkylineFlyingHighwayMovementConstraint::Tunnel)
			SplineSpeed = HighwaySplineSpeed;

		SetActorControlSide(Game::Zoe);

	}

	



	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaTime)
	{	
		if(Car == nullptr)
		{
			for (auto Player : Game::Players)
			{
				auto PilotComponent = USkylineFlyingCarPilotComponent::Get(Player);
				if (PilotComponent != nullptr)
				{
					if (PilotComponent.Car != nullptr)
					{
						// TargetActor = PilotComponent.Car;
						Car = PilotComponent.Car;
					}
				}
			}
		}

		DetectionField.SetWorldScale3D(Math::VInterpConstantTo(DetectionField.WorldScale, FVector(DetectionFieldTargetScale), DeltaTime, 5));
		if(DetectionField.WorldScale == FVector(DetectionFieldTargetScale))
		{
			if(DetectionFieldTargetScale == 10)
				DetectionFieldTargetScale = DetectionFieldScale;
			else
				DetectionFieldTargetScale = 10;
		}

		if(!bActivated)
			return;
		
		
		if(!bTargetDetected)
		{
			SplinePosition.Move(SplineSpeed * DeltaTime);

			FTransform Transform = SplinePosition.WorldTransformNoScale;
			Transform.Location = Transform.Location + Transform.TransformVectorNoScale(OffsetFromSpline);

			SetActorLocationAndRotation(Transform.Location, Transform.Rotation);
		}

		MeshComp.AddWorldRotation(FRotator(0, 0, 40 * DeltaTime));

		// FVector ProjectedCarLocation = Car.ActorLocation.PointPlaneProject(ActorLocation, ActorForwardVector);	
		FVector Location = ActorLocation + (Car.ActorLocation - ActorLocation).GetClampedToSize(0.0, Offset);
		MeshRoot.WorldLocation = Math::VInterpTo(MeshRoot.WorldLocation, Location, DeltaTime, HomingSpeed);

		if(!bTargetDetected)
			return;

		HomingSpeed += DeltaTime * 30;
	}


	UFUNCTION()
	private void OnFieldBeginOverlap(UPrimitiveComponent OverlappedComponent, AActor OtherActor,
	                                     UPrimitiveComponent OtherComp, int OtherBodyIndex,
	                                     bool bFromSweep, const FHitResult&in SweepResult)
	{

		// Car = Cast<ASkylineFlyingCar>(OtherActor);
		// if(Car != nullptr)
		// {
		// 	bTargetDetected = true;
		// 	Car.TakeDamage();
		// 	Explode();
		// }

	}


	UFUNCTION()
	private void OnCollisionBeginOverlap(UPrimitiveComponent OverlappedComponent, AActor OtherActor,
	                                     UPrimitiveComponent OtherComp, int OtherBodyIndex,
	                                     bool bFromSweep, const FHitResult&in SweepResult)
	{

		if(!HasControl())
			return;

		Car = Cast<ASkylineFlyingCar>(OtherActor);
		if(Car != nullptr)
		{
			CrumbImpactWithCar();
		}

		
	}

	UFUNCTION()
	private void OnTakeDamage(AHazeActor ActorTakingDamage, AHazeActor Attacker, float Damage,
	                          EDamageType DamageType)
	{
		if(!HasControl())
			return;

		if(HealthComp.IsDead())
			CrumbExplode();
	}

	UFUNCTION(CrumbFunction)
	void CrumbImpactWithCar()
	{
		FSkylineFlyingCarDamage CarDamage;
		CarDamage.Amount = DamageAmount;
		Car.TakeDamage(CarDamage);

		CrumbExplode();
	}


	UFUNCTION(CrumbFunction)
	private void CrumbExplode()
	{
		Niagara::SpawnOneShotNiagaraSystemAtLocation(ExplosionNiagara, MeshRoot.WorldLocation);
		TriggerExplosionAudio();

		if(WarningWidget != nullptr)
		{
			Game::Mio.RemoveWidget(WarningWidget);
			WarningWidget = nullptr;
		}

		DestroyActor();
	}

	UFUNCTION(BlueprintEvent)
	void TriggerExplosionAudio(){}

	UFUNCTION()
	private void Activate()
	{
		DetectionField.OnComponentBeginOverlap.AddUFunction(this, n"OnFieldBeginOverlap");
		Collision.OnComponentBeginOverlap.AddUFunction(this, n"OnCollisionBeginOverlap");

		WarningWidget = Game::Mio.AddWidget(WarningWidgetClass);
		WarningWidget.AttachWidgetToComponent(MeshRoot);

		auto Spline = Highway.HighwaySpline;

		SplinePosition = Spline.GetClosestSplinePositionToWorldLocation(ActorLocation);
		OffsetFromSpline = SplinePosition.WorldTransformNoScale.InverseTransformPositionNoScale(ActorLocation);

		if(DetectionField.WorldScale.X < DetectionFieldScale)
				DetectionField.SetWorldScale3D(FVector(DetectionFieldScale));

		bActivated = true;
	}

	UFUNCTION()
	private void OnTriggerBeginOverlap(UPrimitiveComponent OverlappedComponent, AActor OtherActor,
	                                   UPrimitiveComponent OtherComp, int OtherBodyIndex, bool bFromSweep,
	                                   const FHitResult&in SweepResult)
	{
		Car = Cast<ASkylineFlyingCar>(OtherActor);
		if(Car != nullptr)
		{
			if(WarningWidget != nullptr)
			{
				Game::Mio.RemoveWidget(WarningWidget);
				WarningWidget = nullptr;
			}
		}
	
	}

	UFUNCTION(NotBlueprintCallable)
	private void OnColliderBeginOverlap(UPrimitiveComponent OverlappedComponent, AActor OtherActor, UPrimitiveComponent OtherComp, int OtherBodyIndex, bool bFromSweep, const FHitResult&in SweepResult)
	{
		if (!HasControl())
			return;

		ASkylineFlyingCar FlyingCar = Cast<ASkylineFlyingCar>(OtherActor);
		if (FlyingCar == nullptr)
			return;

		CrumbCarImpact(FlyingCar);
	}

	UFUNCTION(CrumbFunction)
	private void CrumbCarImpact(ASkylineFlyingCar FlyingCar)
	{
		FSkylineFlyingCarDamage CarDamage;
		CarDamage.Amount = DamageAmount;
		FlyingCar.TakeDamage(CarDamage);

		CrumbExplode();
	}




	UFUNCTION()
	private void OnActorEnter(AHazeActor Actor)
	{
		Activate();
	}

}