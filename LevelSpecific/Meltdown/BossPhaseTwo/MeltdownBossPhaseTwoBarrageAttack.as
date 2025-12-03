enum EMeltdownBossBarrageAttackTargetingType
{
	// Randomized position in the arena
	RandomPosition,
	// Target a random player
	RandomPlayer,
	// Always target mio
	Mio,
	// Always target zoe
	Zoe,
}

struct FMeltdownBossPhaseTwoBarrageConfig
{
	UPROPERTY()
	int ProjectileCount = 10;
	UPROPERTY()
	float StartLaunchingDelay = 1.0;
	UPROPERTY()
	float LaunchInterval = 1.0;
	UPROPERTY()
	float ProjectileSpeed = 5000.0;
	UPROPERTY()
	float ProjectileGravity = 2000.0;
	UPROPERTY()
	float ExplosionRadius = 200.0;

	UPROPERTY()
	EMeltdownBossBarrageAttackTargetingType TargetingType = EMeltdownBossBarrageAttackTargetingType::RandomPosition;
	// World offset added to the targeting (not used when targeting is Random)
	UPROPERTY()
	FVector TargetingWorldOffset;
	UPROPERTY()
	FVector TargetingRandomWorldDistance;
	// Predict the player's velocity forward in time for the targeting (only used when targeting player)
	UPROPERTY()
	float TargetingPredictionTime = 0.0;
	// Predict forward from where the player is moving by this much distance
	UPROPERTY()
	float TargetingPredictionDistance = 0.0;
}

UCLASS(Abstract)
class AMeltdownBossPhaseTwoBarrageAttack : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

#if EDITOR
	UPROPERTY(DefaultComponent)
	UEditorBillboardComponent Billboard;
#endif

	UPROPERTY(DefaultComponent)
	UBoxComponent AppearBox;
	UPROPERTY(DefaultComponent)
	UBoxComponent AppearBox_Right;

	UPROPERTY(DefaultComponent)
	UBoxComponent WaterfallBox;
	UPROPERTY(DefaultComponent)
	UBoxComponent WaterfallBox_Right;

	UPROPERTY(DefaultComponent)
	UBoxComponent TargetBox;

	UPROPERTY(EditAnywhere)
	TSubclassOf<AMeltdownBossPhaseTwoBarrageProjectile> ProjectileClass;
	UPROPERTY(EditAnywhere)
	TSubclassOf<AMeltdownBossPhaseTwoBarrageTelegraph> TelegraphClass;

	access PrivateWithMeltdownHomingBall = private, AMeltdownBossPhaseTwoHomingBall;
	access:PrivateWithMeltdownHomingBall TArray<AMeltdownBossPhaseTwoHomingBall> ActiveHomingBalls;
	bool GetActiveHomingBalls(TArray<AMeltdownBossPhaseTwoHomingBall>&out HomingBalls)
	{
		HomingBalls = ActiveHomingBalls;
		return !HomingBalls.IsEmpty();
	}

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
	}

	UFUNCTION(DevFunction)
	void StartAttack(FMeltdownBossPhaseTwoBarrageConfig Config)
	{
		if (!HasControl())
			return;

		NetSpawnProjectilesForAttack(Config, Math::Rand());
	}

	UFUNCTION(NetFunction)
	void NetSpawnProjectilesForAttack(FMeltdownBossPhaseTwoBarrageConfig Config, int RandomSeed)
	{
		FRandomStream RandomStream(RandomSeed);

		for (int i = 0, Count = Config.ProjectileCount; i < Count; ++i)
		{
			UBoxComponent AppearLocation = AppearBox;
			if (i % 2 == 0)
				AppearLocation = AppearBox_Right;	

			FVector StartLocation = AppearLocation.WorldTransform.TransformPosition(FVector(
				RandomStream.RandRange(-AppearLocation.BoxExtent.X, AppearLocation.BoxExtent.X),
				RandomStream.RandRange(-AppearLocation.BoxExtent.Y, AppearLocation.BoxExtent.Y),
				RandomStream.RandRange(-AppearLocation.BoxExtent.Z, AppearLocation.BoxExtent.Z),
			));

			FVector TargetLocation = TargetBox.WorldTransform.TransformPosition(FVector(
				RandomStream.RandRange(-TargetBox.BoxExtent.X, TargetBox.BoxExtent.X),
				RandomStream.RandRange(-TargetBox.BoxExtent.Y, TargetBox.BoxExtent.Y),
				RandomStream.RandRange(-TargetBox.BoxExtent.Z, TargetBox.BoxExtent.Z),
			));

			AHazePlayerCharacter TargetPlayer;
			if (Config.TargetingType == EMeltdownBossBarrageAttackTargetingType::RandomPlayer)
				TargetPlayer = Game::GetPlayer(EHazePlayer(RandomStream.RandRange(0, 1)));
			else if (Config.TargetingType == EMeltdownBossBarrageAttackTargetingType::Mio)
				TargetPlayer = Game::Mio;
			else if (Config.TargetingType == EMeltdownBossBarrageAttackTargetingType::Zoe)
				TargetPlayer = Game::Zoe;
			else
				TargetPlayer = nullptr;

			FRotator StartRotation = FRotator::MakeFromZX(FVector::UpVector, TargetLocation - StartLocation);

			auto Telegraph = Cast<AMeltdownBossPhaseTwoBarrageTelegraph>(
				SpawnActor(TelegraphClass, TargetLocation));
			Telegraph.Telegraph.SetRadius(Config.ExplosionRadius);

			auto Projectile = Cast<AMeltdownBossPhaseTwoBarrageProjectile>(
				SpawnActor(ProjectileClass, StartLocation, StartRotation));
			Projectile.SourceAttack = this;
			Projectile.Telegraph = Telegraph;
			Projectile.HorizontalSpeed = Config.ProjectileSpeed;
			Projectile.Gravity = Config.ProjectileGravity;
			Projectile.TargetingType = Config.TargetingType;
			Projectile.TargetLocation = TargetLocation;
			Projectile.TargetWorldOfset = Config.TargetingWorldOffset;
			Projectile.TargetRandomWorldDistance = Config.TargetingRandomWorldDistance;
			Projectile.TargetPredictionTime = Config.TargetingPredictionTime;
			Projectile.TargetPredictionDistance = Config.TargetingPredictionDistance;
			Projectile.ExplosionRadius = Config.ExplosionRadius;
			Projectile.TargetBox = TargetBox;
			Projectile.TargetPlayer = TargetPlayer;

			Projectile.Appear();

			Timer::SetTimer(Projectile, n"Launch", Math::Max(Config.StartLaunchingDelay + Config.LaunchInterval * i, 0.01));
		}
	}
};

UCLASS(Abstract)
class AMeltdownBossPhaseTwoBarrageProjectile : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent)
	UHazeListedActorComponent ListedComponent;

	UPROPERTY(EditAnywhere)
	TSubclassOf<UDamageEffect> SharkImpactDamage;

	UPROPERTY(EditAnywhere)
	TSubclassOf<UCameraShakeBase> SharkShake;

	UPROPERTY(DefaultComponent)
	UForceFeedbackComponent SharkFF;

#if EDITOR
	UPROPERTY(DefaultComponent)
	UEditorBillboardComponent Billboard;
#endif

	float Gravity = 2000.0;
	float HorizontalSpeed = 3000.0;
	float ExplosionRadius = 200.0;
	FVector TargetLocation;
	AMeltdownBossPhaseTwoBarrageTelegraph Telegraph;
	AMeltdownBossPhaseTwoBarrageAttack SourceAttack;

	UPROPERTY()
	TSubclassOf<AMeltdownBossPhaseTwoHomingBall> HomingBallClass;

	EMeltdownBossBarrageAttackTargetingType TargetingType;
	AHazePlayerCharacter TargetPlayer;
	FVector TargetWorldOfset;
	FVector TargetRandomWorldDistance;
	float TargetPredictionTime;
	float TargetPredictionDistance;
	UBoxComponent TargetBox;

	private float LaunchTimer = 0.0;
	private FVector Velocity;
	private bool bLaunched = false;
	private bool bPassedThroughWaterfall = false;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		AddActorDisable(this);
	}

	UFUNCTION(DevFunction)
	void Appear()
	{
		RemoveActorDisable(this);
		HideShark();

	//	if (AppearEffect != nullptr)
	//		Niagara::SpawnOneShotNiagaraSystemAtLocation(AppearEffect, ActorLocation);
	}

	UFUNCTION(BlueprintEvent)
	void HideShark()
	{

	}

	UFUNCTION(BlueprintEvent)
	void UnHideHideShark()
	{

	}


	UFUNCTION(DevFunction)
	void Launch()
	{
		bLaunched = true;
		UnHideHideShark();
		Velocity = Trajectory::CalculateVelocityForPathWithHorizontalSpeed(
			ActorLocation, TargetLocation, Gravity, HorizontalSpeed
		);

		if (Telegraph != nullptr)
			Telegraph.RemoveActorDisable(Telegraph);

		UMeltdownBossPhaseTwoBarrageProjectileEffectHandler::Trigger_SpawnProjectile(this);
	}

	UFUNCTION(DevFunction)
	void DevLaunchAtMio()
	{
		TargetLocation = Game::Mio.ActorLocation;
		Launch();
	}

	void UpdateTargeting()
	{
		if (TargetPlayer == nullptr)
			return;
		if (TargetingType == EMeltdownBossBarrageAttackTargetingType::RandomPosition)
			return;

		TargetLocation = TargetPlayer.ActorLocation;
		TargetLocation += TargetWorldOfset;
		TargetLocation += TargetPlayer.ActorVelocity * TargetPredictionTime;
		TargetLocation += TargetPlayer.ActorVelocity.GetSafeNormal() * TargetPredictionDistance;
		TargetLocation.X += Math::RandRange(-TargetRandomWorldDistance.X, TargetRandomWorldDistance.X);
		TargetLocation.Y += Math::RandRange(-TargetRandomWorldDistance.X, TargetRandomWorldDistance.X);
		TargetLocation.Z += Math::RandRange(-TargetRandomWorldDistance.X, TargetRandomWorldDistance.X);

		if (TargetBox != nullptr)
		{
			FVector BoxLocalLocation = TargetBox.WorldTransform.InverseTransformPosition(TargetLocation);
			BoxLocalLocation = BoxLocalLocation.ComponentClamp(
				-TargetBox.BoxExtent,
				TargetBox.BoxExtent,
			);

			TargetLocation = TargetBox.WorldTransform.TransformPosition(BoxLocalLocation);
		}

		ActorRotation = FRotator::MakeFromZX(FVector::UpVector, TargetLocation - ActorLocation);
		Telegraph.ActorLocation = TargetLocation + FVector(0, 0, -50);
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		if (bLaunched)
		{
			LaunchTimer += DeltaSeconds;

			FVector DeltaMove = Velocity * DeltaSeconds;
			DeltaMove += FVector::DownVector * 0.5 * DeltaSeconds * DeltaSeconds * Gravity;
			Velocity += FVector::DownVector * DeltaSeconds * Gravity;

			FVector NewLocation = ActorLocation + DeltaMove;
			if (!NewLocation.Equals(ActorLocation))
			{
				FHazeTraceSettings Trace;
				Trace.UseLine();
				Trace.TraceWithChannel(ECollisionChannel::WeaponTraceEnemy);
				Trace.IgnoreActor(this);
				Trace.IgnorePlayers();

				FHitResult Hit = Trace.QueryTraceSingle(ActorLocation, NewLocation);
				if (Hit.bBlockingHit && LaunchTimer > 1.0)
				{
					ActorLocation = Hit.Location;
					SpawnHomingBalls();
					Explode();
					return;
				}
				else if (LaunchTimer >= 10.0)
				{
					Explode();
					return;
				}
				else
				{
					SetActorLocationAndRotation(
						NewLocation,
						FRotator::MakeFromX(DeltaMove)
					);
				}
			}

			if (!bPassedThroughWaterfall)
			{
				if (
					Shape::IsPointInside(SourceAttack.WaterfallBox.GetCollisionShape(), SourceAttack.WaterfallBox.WorldTransform, ActorLocation)
					|| Shape::IsPointInside(SourceAttack.WaterfallBox_Right.GetCollisionShape(), SourceAttack.WaterfallBox_Right.WorldTransform, ActorLocation)
				)
				{
					UMeltdownBossPhaseTwoBarrageProjectileEffectHandler::Trigger_PassThroughWaterfall(this);
					bPassedThroughWaterfall = true;
				}
			}
		}
		else
		{
			UpdateTargeting();
		}
	}

	void SpawnHomingBalls()
	{
		if (!HomingBallClass.IsValid())
			return;

		const int SpawnCount = 3;
		const float Distance = 10.0;
		const float AngleSpacing = 360.0 / SpawnCount;

		for (int i = 0; i < SpawnCount; ++i)
		{
			FRotator Rotation;
			Rotation.Yaw = AngleSpacing * i;
			auto HomingBall = SpawnActor(HomingBallClass, ActorLocation + Rotation.ForwardVector * Distance, Rotation, bDeferredSpawn = true);
			HomingBall.BarrageAttack = SourceAttack;		
			FinishSpawningActor(HomingBall);

			FMeltdownBossPhaseTwoHomingBallSpawnParams Params;
			Params.Location = HomingBall.ActorLocation;
			UMeltdownBossPhaseTwoHomingBallEffectHandler::Trigger_SpawnHomingBall(SourceAttack, Params);
		}
	}
//
	void Explode()
	{
		for (AHazePlayerCharacter Player : Game::Players)
		{
			Player.PlayWorldCameraShake(SharkShake,this, ActorLocation, 600, 1800);
			SharkFF.Play();

			if (Player.ActorCenterLocation.Distance(ActorLocation) < ExplosionRadius + Player.CapsuleComponent.ScaledCapsuleRadius)
				Player.DamagePlayerHealth(0.5, DamageEffect = SharkImpactDamage);
		}
		

		FMeltdownBossPhaseTwoBarrageProjectileHitParams HitParams;
		HitParams.HitLocation = ActorLocation;
		UMeltdownBossPhaseTwoBarrageProjectileEffectHandler::Trigger_ProjectileImpact(this, HitParams);

		Telegraph.DestroyActor();

		AddActorVisualsBlock(this);
		AddActorTickBlock(this);

		Timer::SetTimer(this, n"Die", 5);
	}

	UFUNCTION()
	private void Die()
	{
		DestroyActor();
	}
}

UCLASS(Abstract)
class AMeltdownBossPhaseTwoBarrageTelegraph : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;
	UPROPERTY(DefaultComponent)
	UTelegraphDecalComponent Telegraph;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		AddActorDisable(this);
	}
}

struct FMeltdownBossPhaseTwoBarrageProjectileHitParams
{
	UPROPERTY()
	FVector HitLocation;
}

struct FMeltdownBossPhaseTwoHomingBallSpawnParams
{
	UPROPERTY()
	FVector Location;
}

UCLASS(Abstract)
class UMeltdownBossPhaseTwoBarrageProjectileEffectHandler : UHazeEffectEventHandler
{
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void SpawnProjectile() {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void PassThroughWaterfall() {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void ProjectileImpact(FMeltdownBossPhaseTwoBarrageProjectileHitParams HitParams) {}
}

UCLASS(Abstract)
class UMeltdownBossPhaseTwoHomingBallEffectHandler : UHazeEffectEventHandler
{
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void SpawnHomingBall(FMeltdownBossPhaseTwoHomingBallSpawnParams Params) {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void StartUnSpawnHomingBall(FMeltdownBossPhaseTwoHomingBallSpawnParams Params) {}
}

UCLASS(Abstract)
class AMeltdownBossPhaseTwoHomingBall : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent)
	UStaticMeshComponent Mesh;

	UPROPERTY(DefaultComponent, Attach = Mesh)
	UNiagaraComponent Effect;

	UPROPERTY(DefaultComponent, Attach = Effect)
	UDecalTrailComponent Trail;

	UPROPERTY(DefaultComponent, Attach = Mesh)
	UDamageTriggerComponent Trigger;
	default Trigger.bApplyKnockbackImpulse = true;
	default Trigger.HorizontalKnockbackStrength = 900;
	default Trigger.VerticalKnockbackStrength = 1200;
	default Trigger.KnockbackForwardDirectionBlend = 1.0;

	const float Lifetime = 3.0;
	const float InitialSpeed = 500.0;
	const float Acceleration = 500.0;

	float Timer = 0.0;
	float RotationalVelocity = 90.0;
	float Speed;
	bool bHasStartedUnSpawn = false;

	AMeltdownBossPhaseTwoBarrageAttack BarrageAttack;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		Speed = InitialSpeed;
		BarrageAttack.ActiveHomingBalls.Add(this);
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		Timer += DeltaSeconds;
		if (Timer > Lifetime)
		{
			AddActorVisualsBlock(this);
//			DestroyActor();
			return;
		}

		FRotator Rotation = ActorRotation;
		Rotation.Yaw += RotationalVelocity * DeltaSeconds;

		Speed += Acceleration * DeltaSeconds;

		FVector Location = ActorLocation;
		Location += Rotation.ForwardVector * Speed * DeltaSeconds;

		SetActorLocationAndRotation(Location, Rotation);

		// Scale the actor down while it disappears
		if (Timer > Lifetime - 0.3)
		{
			Effect.Deactivate();
			Trigger.DisableDamageTrigger(this);

			Mesh.SetScalarParameterValueOnMaterials(
				n"Smoothstep",
				Math::GetMappedRangeValueClamped(
					FVector2D(Lifetime - 0.3, Lifetime),
					FVector2D(-0.5, 0.0),
					Timer
				)
			);

			SetActorScale3D(FVector(
				Math::GetMappedRangeValueClamped(
					FVector2D(Lifetime - 0.3, Lifetime),
					FVector2D(1.0, 0.01),
					Timer
				)
			));

			if(!bHasStartedUnSpawn)
			{
				bHasStartedUnSpawn = true;
				
				FMeltdownBossPhaseTwoHomingBallSpawnParams Params;
				Params.Location = ActorLocation;
				UMeltdownBossPhaseTwoHomingBallEffectHandler::Trigger_StartUnSpawnHomingBall(BarrageAttack, Params);

				BarrageAttack.ActiveHomingBalls.RemoveSingleSwap(this);
			}
		}
	}
}