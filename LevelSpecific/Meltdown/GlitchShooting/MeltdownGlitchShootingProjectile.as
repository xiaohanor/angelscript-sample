UCLASS(Abstract)
class AMeltdownGlitchShootingProjectile : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;
	
	UPROPERTY(DefaultComponent)
	USceneComponent ChargeScaleRoot;

	UPROPERTY()
	float StartScale = 0.05;
	UPROPERTY()
	float ChargeScale = 0.75;
	UPROPERTY()
	float ProjectileScale = 1.0;

	const float MaxAliveTime = 0.5;

	FVector ShootDirection;
	float Speed;
	float Acceleration;
	float MaxSpeed;
	AHazePlayerCharacter OwningPlayer;
	float TimeOfSpawned = -1.0;
	float TimeOfFired = -1.0;
	float Damage = 1.0;
	bool bIsMoving = false;

	FVector HomingOffset;
	FVector AimTargetLocation;
	FVector ShootOffset;
	USceneComponent AimTargetComponent;
	FVector AutoAimRelativeLocation;

	FVector InitialVelocity;
	int ProjectileIndex = 0;
	EMeltdownGlitchProjectileType ProjectileType;
	FQuat OriginalPlane;

	UHazeActorLocalSpawnPoolComponent ProjectilePool;

	bool bHasTicked;
	bool bHasHit;
	float DestroyTimer = 0.0;

	UFUNCTION(BlueprintEvent)
	void BP_Spawn() {}
	UFUNCTION(BlueprintEvent)
	void BP_Fire() {}

	void Initialize()
	{
		RemoveActorDisable(this);
		UMeltdownGlitchShootingProjectileEffectHandler::Trigger_OnProjectileSpawned(this);
		TimeOfSpawned = Time::GetGameTimeSeconds();
		bIsMoving = false;
		bHasTicked = false;
		bHasHit = false;
		DestroyTimer = 0.0;
		BP_Spawn();

	//	ChargeScaleRoot.SetWorldScale3D(FVector(StartScale, StartScale, StartScale));
	}

	void Fire()
	{
		DetachRootComponentFromParent();
		TimeOfFired = Time::GetGameTimeSeconds();
		UMeltdownGlitchShootingProjectileEffectHandler::Trigger_OnProjectileFired(this);
		bIsMoving = true;
		BP_Fire();

		if (ProjectileType == EMeltdownGlitchProjectileType::Missile)
		{
			if (IsValid(AimTargetComponent))
				AutoAimRelativeLocation = AimTargetComponent.WorldTransform.InverseTransformPosition(AimTargetLocation);

			if (OwningPlayer.GetCurrentGameplayPerspectiveMode() == EPlayerMovementPerspectiveMode::TopDown)
				OriginalPlane = FQuat::MakeFromZX(FVector::RightVector, ShootDirection);
			else
				OriginalPlane = FQuat::MakeFromZX(FVector::UpVector, ShootDirection);

			FQuat ShootRotation = FQuat::MakeFromX(ShootDirection);
			ShootRotation = ShootRotation * FQuat(FVector::RightVector, Math::RandRange(-0.1 * PI, -0.3 * PI) * 0.5);
			ShootRotation = ShootRotation * FQuat(FVector::UpVector, Math::RandRange(-0.15 * PI, 0.15 * PI) * 0.5);

			ShootDirection = ShootRotation.ForwardVector;
		}
		else if (ProjectileType == EMeltdownGlitchProjectileType::HomingBullet)
		{
			HomingOffset = ShootOffset;
		}
	}

	void Fizzle()
	{
		AddActorDisable(this);
		ProjectilePool.UnSpawn(this);
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		if (DestroyTimer > 0)
		{
			DestroyTimer -= DeltaSeconds;
			if (DestroyTimer <= 0)
			{
				Fizzle();
			}
			return;
		}

		if (!bIsMoving)
		{
			ChargeScaleRoot.SetWorldScale3D(FVector(ChargeScale));
		}
		else if (bHasTicked)
		{
			float AliveTime = Time::GetGameTimeSince(TimeOfFired);
			if(AliveTime > MaxAliveTime)
			{
				UMeltdownGlitchShootingProjectileEffectHandler::Trigger_OnProjectileExpired(this);
				Kill();
				return;
			}


			FVector Delta;

			if (ProjectileType == EMeltdownGlitchProjectileType::Missile)
			{
				if (IsValid(AimTargetComponent))
					AimTargetLocation = AimTargetComponent.WorldTransform.TransformPosition(AutoAimRelativeLocation);

				FVector Target = AimTargetLocation;
				float SettleAlpha = Math::Saturate(AliveTime / 1.0);

				float Rotation = TWO_PI * AliveTime + ProjectileIndex;
				Delta += FQuat(OriginalPlane.ForwardVector, Rotation) * (OriginalPlane.RightVector * 1000.0 * DeltaSeconds * SettleAlpha);

				float RotationSpeed = 180 * SettleAlpha;
				ShootDirection = Math::VInterpNormalRotationTo(
					ShootDirection, (Target - ActorLocation).GetSafeNormal(),
					DeltaSeconds, RotationSpeed);

				if ((Target - ActorLocation).DotProduct(OriginalPlane.ForwardVector) < 0)
				{
					UMeltdownGlitchShootingProjectileEffectHandler::Trigger_OnProjectileExpired(this);
					Kill();
					return;
				}
			}
			else if (ProjectileType == EMeltdownGlitchProjectileType::HomingBullet)
			{
				float Angle = TWO_PI * AliveTime * 5.0;

				FVector RotationAxis = ActorForwardVector;
				FVector Offset = ShootOffset;
				Offset = FQuat(RotationAxis, Angle) * Offset;

				ActorLocation = ActorLocation - HomingOffset + Offset;
				HomingOffset = Offset;
			}

			Delta += InitialVelocity * DeltaSeconds;
			Delta += ShootDirection * (Speed * DeltaSeconds);
			Speed += Acceleration * DeltaSeconds;
			Speed = Math::Clamp(Speed, 0.0, MaxSpeed);

			if(Delta.IsNearlyZero())
				return;

			FHazeTraceSettings Trace = Trace::InitChannel(ECollisionChannel::PlayerAiming);
			Trace.UseLine();
			Trace.SetReturnPhysMaterial(true);

			FHitResult Hit = Trace.QueryTraceSingle(ActorLocation, ActorLocation + Delta);
			if (Hit.bBlockingHit)
			{
				TArray<UMeltdownGlitchShootingResponseComponent> ResponseComps;
				Hit.Actor.GetComponentsByClass(UMeltdownGlitchShootingResponseComponent, ResponseComps);

				bool bHitRader = Hit.Actor.IsA(AMeltdownBoss);
				FMeltdownGlitchImpact Impact;
				Impact.FiringPlayer = OwningPlayer;
				Impact.ImpactPoint = Hit.ImpactPoint;
				Impact.ImpactNormal = Hit.ImpactNormal;
				Impact.Damage = Damage;
				Impact.ProjectileDirection = ShootDirection;

				for (auto ResponseComp : ResponseComps)
					ResponseComp.TriggerGlitchHit(Impact);

				FMeltdownGlitchProjectileImpactEffectParams HitEffectParams;
				HitEffectParams.ResponseComponents = ResponseComps;
				HitEffectParams.ImpactPoint = Hit.ImpactPoint;
				HitEffectParams.ImpactNormal = Hit.ImpactNormal;
				HitEffectParams.PhysMat = Hit.PhysMaterial;
				HitEffectParams.ProjectileLocation = ActorLocation;
				HitEffectParams.bHitRader = bHitRader;
				UMeltdownGlitchShootingProjectileEffectHandler::Trigger_OnProjectileHit(this, HitEffectParams);

				Kill();
				return;
			}

			if (!Delta.IsNearlyZero())
			{
				AddActorWorldOffset(Delta);
				SetActorRotation(FRotator::MakeFromX(Delta));
			}
		}
		else
		{
			bHasTicked = true;
		}
	}

	void Kill()
	{
		TimeOfFired = -1.0;
		DestroyTimer = 1.0;
		bHasHit = true;
	}
};