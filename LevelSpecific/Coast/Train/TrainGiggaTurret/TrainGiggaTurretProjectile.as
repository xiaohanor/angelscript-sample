class ATrainGiggaTurretProjectile : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent RootComp;

	UPROPERTY(DefaultComponent)
	USceneComponent RotationRoot;

	UPROPERTY(DefaultComponent, Attach = RotationRoot)
	UStaticMeshComponent Mesh;

	UPROPERTY(DefaultComponent, Attach = Mesh)
	UNiagaraComponent TrailFX;

	UPROPERTY()
	UNiagaraSystem ImpactExplosion;

	AHazePlayerCharacter TargetPlayer;

	UPROPERTY()
	TSubclassOf<UCameraShakeBase> ImpactCamShake;

	UPROPERTY()
	UHazeCapabilitySheet WingSuitSheet;

	UPROPERTY()
	UHazeComposableSettings WingsuitSettings;

	FVector ExplosionLocation;

	bool bHasBlownUp = false;

	AHazeActor FocusActor;

	FVector TrainTurretRightVector;

	FVector TrainTurretForwardVector;

	FVector ImpactLocation = FVector::ZeroVector;

	FVector StartLocation = FVector::ZeroVector;

	float MeshRelativeZOffsetValue = 100.0;

	float RotationMultiplier = 0.0;

	float LerpSpeed;

	float Alpha;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{

	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		MeshRelativeZOffsetValue = 20.0 * Math::Sin(Time::GameTimeSeconds * 5);
		Mesh.SetRelativeLocation(FVector(0.0, 0.0, MeshRelativeZOffsetValue));

		FVector DirectionToPlayer = TargetPlayer.ActorLocation - ActorLocation;
		FRotator DirectionRotation = FRotator::MakeFromX(DirectionToPlayer);
		
		RotationRoot.SetWorldRotation(DirectionRotation);

		RotationRoot.AddRelativeRotation(FRotator(0.0, 0.0, 1 * RotationMultiplier));
		RotationMultiplier += 20 * DeltaSeconds;

		Alpha += 2 * DeltaSeconds;
		Alpha = Math::Clamp(Alpha, 0.0, 1.0);
		FVector NewLocation = Math::Lerp(StartLocation, TargetPlayer.ActorLocation, Alpha);

		SetActorLocation(NewLocation);

		// Debug::DrawDebugDirectionArrow(FocusActor.ActorLocation, TrainTurretForwardVector, 4000.0, 5000.0, Duration = 0.0);

		if (Alpha >= 1)
		{
			BlowUp();
		}
	}

	void BlowUp()
	{
		if (bHasBlownUp)
			return;

		FHazeTraceSettings Trace;
		Trace = Trace::InitObjectType(EObjectTypeQuery::PlayerCharacter);
		Trace.UseSphereShape(500.0);
		Trace.IgnoreActor(this);
		Trace.DebugDraw(1.0);
		
		FHitResultArray HitResults = Trace.QueryTraceMulti(ActorLocation, ActorLocation);

		for (auto Overlap : HitResults)
		{
			auto Player = Cast<AHazePlayerCharacter>(Overlap.Actor);
			
			FVector Direction = (ActorLocation - StartLocation).GetSafeNormal();

			float PlayerTurretDot = Direction.DotProduct(TrainTurretRightVector);
			
			//Impulse at impact //poo
			FVector ImpulseDirection = Player.ActorLocation - ActorLocation;
			ImpulseDirection.Normalize();
			
			Player.AddMovementImpulse((TrainTurretRightVector * (4000 * Math::Sign(PlayerTurretDot))) + (FVector::UpVector * 8000.0) + (TrainTurretForwardVector * 2000.0), n"TurretImpulse");

			// Player.PlayWorldCameraShake(ImpactCamShake, this, ActorLocation, 1000.0, 5000.0);

			auto POIBOY = Player.CreatePointOfInterest();
			POIBOY.Settings.Duration = 2.0;
			POIBOY.FocusTarget.SetFocusToActor(FocusActor);
			POIBOY.Apply(this, 2);

			Player.StartCapabilitySheet(WingSuitSheet, this);
			Player.ApplySettings(WingsuitSettings, this, EHazeSettingsPriority::Gameplay);
		}

		ExplosionLocation = ActorLocation;
		bHasBlownUp = true;
		Mesh.SetHiddenInGame(true);
		Timer::SetTimer(this, n"ExplodeTrain", 3.0);

	}

	UFUNCTION()
	void ExplodeTrain()
	{
		Niagara::SpawnOneShotNiagaraSystemAtLocation(ImpactExplosion, FocusActor.ActorLocation);
		DestroyActor();
	}
}