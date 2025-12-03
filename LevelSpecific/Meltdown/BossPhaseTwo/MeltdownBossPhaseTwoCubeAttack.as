event void FCubeLanded();

UCLASS(Abstract)
class AMeltdownBossPhaseTwoCubeAttack : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent)
	UDeathTriggerComponent KillTrigger;
	default KillTrigger.Shape = FHazeShapeSettings::MakeBox(FVector(250));

	UPROPERTY(DefaultComponent)
	USceneComponent TargetLocation;
	default TargetLocation.RelativeLocation = FVector(0, 0, -1000);

	UPROPERTY(DefaultComponent)
	USceneComponent ProjectileSpawnPoint;
	default ProjectileSpawnPoint.RelativeLocation = FVector(0, 0, -250);

#if EDITOR
	UPROPERTY(DefaultComponent, Attach = TargetLocation)
	UEditorBillboardComponent TargetBillboard;
	UPROPERTY(DefaultComponent, Attach = ProjectileSpawnPoint)
	UEditorBillboardComponent ProjectileSpawnBillboard;
#endif

	UPROPERTY(EditAnywhere)
	UNiagaraSystem SplitEffect;
	UPROPERTY(EditAnywhere)
	TSubclassOf<AMeltdownBossPhaseTwoCubeProjectile> ProjectileClass;
	UPROPERTY(EditAnywhere)
	int ProjectileCount = 8;
	UPROPERTY(EditAnywhere)
	float ProjectileSpawnDistance = 100.0;
	UPROPERTY(EditAnywhere)
	float Gravity = 2000.0;

	private FTransform OriginalTransform;
	private float VerticalSpeed = 0.0; 
	private float TargetHeight;

	UPROPERTY()
	FCubeLanded CubeLanded;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		AddActorDisable(this);
		OriginalTransform = ActorTransform;
	}

	UFUNCTION(DevFunction)
	void Launch()
	{
		VerticalSpeed = 0.0;
		TargetHeight = TargetLocation.WorldLocation.Z;
		RemoveActorDisable(this);
	}

	UFUNCTION(DevFunction)
	void Split()
	{
		Niagara::SpawnOneShotNiagaraSystemAtLocation(SplitEffect, ActorLocation);

		float AngleStep = TWO_PI / ProjectileCount;
		for (int i = 0; i < ProjectileCount; ++i)
		{
			float Angle = AngleStep * i;

			FQuat Rotation = FQuat(FVector::UpVector, Angle);
			FVector Direction = Rotation.ForwardVector;

			auto Projectile = Cast<AMeltdownBossPhaseTwoCubeProjectile>(SpawnActor(
				ProjectileClass,
				ProjectileSpawnPoint.WorldLocation + Direction * ProjectileSpawnDistance,
				Rotation.Rotator(),
			));
			Projectile.Launch();
		}

		AddActorDisable(this);
		ActorTransform = OriginalTransform;
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		if (ActorLocation.Z > TargetHeight)
		{
			VerticalSpeed -= Gravity * DeltaSeconds;

			FVector NewLocation = ActorLocation;
			NewLocation.Z += VerticalSpeed * DeltaSeconds;
			NewLocation.Z -= Gravity * DeltaSeconds * DeltaSeconds * 0.5;
			NewLocation.Z = Math::Max(NewLocation.Z, TargetHeight);
			ActorLocation = NewLocation;

			if (ActorLocation.Z == TargetHeight)
				Landed();
		}
	}

	UFUNCTION(BlueprintEvent)
	void Landed()
	{
		CubeLanded.Broadcast();
	}
};

UCLASS(Abstract)
class AMeltdownBossPhaseTwoCubeProjectile : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

#if EDITOR
	UPROPERTY(DefaultComponent)
	UArrowComponent Arrow;
	default Arrow.RelativeScale3D = FVector(3);
#endif

	UPROPERTY(DefaultComponent)
	UStaticMeshComponent DamageTrigger;
	default DamageTrigger.SetHiddenInGame(true);

	UPROPERTY(EditAnywhere)
	UNiagaraSystem BreakEffect;
	UPROPERTY(EditAnywhere)
	float RotationDuration = 0.4;
	UPROPERTY(EditAnywhere)
	float RotationInterval = 0.1;
	UPROPERTY(EditAnywhere)
	float SingleRotationDistance = 200.0;
	UPROPERTY(EditAnywhere)
	float Duration = 10.0;

	private bool bIsRotating = false;
	private float Timer = 0.0;
	private float Lifetime = 0.0;

	private FQuat StartRotation;
	private FQuat EndRotation;
	private FVector RotationPivot;
	private FVector StartLocation;

	private FTransform OriginalTransform;
	private FVector MovementDirection;
	private FVector RotationAxis;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		AddActorDisable(this);
		OriginalTransform = ActorTransform;
	}

	UFUNCTION(DevFunction)
	void Launch()
	{
		RemoveActorDisable(this);

		MovementDirection = ActorForwardVector;
		RotationAxis = ActorRightVector;
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		Timer += DeltaSeconds;
		Lifetime += DeltaSeconds;

		if (!bIsRotating)
		{
			if (Timer >= RotationInterval)
			{
				Timer -= RotationInterval;
				bIsRotating = true;

				// Trace to see if we need to bounce off something or not
				FHazeTraceSettings Trace;
				Trace.UseBoxShape(FVector(SingleRotationDistance * 0.5));
				Trace.TraceWithChannel(ECollisionChannel::WeaponTraceEnemy);
				Trace.IgnoreActor(this);
				Trace.IgnorePlayers();

				FHitResult Hit = Trace.QueryTraceSingle(ActorLocation, ActorLocation + MovementDirection * SingleRotationDistance);
				if (Hit.bBlockingHit && !Hit.bStartPenetrating)
				{
				//	MovementDirection = -MovementDirection;
				//	RotationAxis = -RotationAxis;
					AddActorDisable(this);
					Niagara::SpawnOneShotNiagaraSystemAtLocation(BreakEffect, ActorLocation);
				}

				StartLocation = ActorLocation;

				RotationPivot = StartLocation;
				RotationPivot += MovementDirection * SingleRotationDistance * 0.5;
				RotationPivot += FVector::DownVector * SingleRotationDistance * 0.5;

				StartRotation = ActorQuat;
				EndRotation = FQuat(RotationAxis, 0.5 * PI) * StartRotation;
			}
		}

		if (bIsRotating)
		{
			float RotationAlpha = Math::EaseInOut(0, 1, Math::Saturate(Timer / RotationDuration), 2);

			ActorQuat = FQuat::Slerp(
				StartRotation, EndRotation, RotationAlpha
			);

			FVector RelativeToPivot = StartLocation - RotationPivot;
			FVector NewPivot = FQuat(RotationAxis, 0.5 * PI * RotationAlpha) * RelativeToPivot;
			ActorLocation = RotationPivot + NewPivot;

			if (Timer >= RotationDuration)
			{
				bIsRotating = false;
				Timer -= RotationDuration;
				RotateEffect();
			}
		}

		if (Lifetime > Duration)
		{
			AddActorDisable(this);
			Niagara::SpawnOneShotNiagaraSystemAtLocation(BreakEffect, ActorLocation);
			ActorTransform = OriginalTransform;
		}

	}

	UFUNCTION(BlueprintEvent)
	void RotateEffect()
	{

	}

};