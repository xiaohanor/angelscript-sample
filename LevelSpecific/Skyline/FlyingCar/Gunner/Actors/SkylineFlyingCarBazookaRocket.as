USTRUCT()
struct FBazookaRocketLaunchParams
{
	UPROPERTY()
	USkylineFlyingCarBazookaTargetableComponent HomingTarget;

	UPROPERTY()
	FVector AimDirection;

	UPROPERTY()
	FVector BaseVelocity;

	UPROPERTY()
	FHazeRange SpeedRange;

	UPROPERTY()
	float SpeedAccelerationDuration;

	UPROPERTY()
	float Damage;
}

event void FRocketExploded(ASkylineFlyingCarBazookaRocket BazookaRocket);

class ASkylineFlyingCarBazookaRocket : AHazeActor
{
	default PrimaryActorTick.bStartWithTickEnabled = false;

	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent)
	UStaticMeshComponent MeshComponent;
	default MeshComponent.SetCollisionEnabled(ECollisionEnabled::NoCollision);

	UPROPERTY(DefaultComponent)
	UCapsuleComponent CollisionCapsule;

	UPROPERTY(DefaultComponent, Attach = MeshComponent)
	UNiagaraComponent TrailNiagaraComponent;

	UPROPERTY(Category = "VFX")
	UNiagaraSystem ExplosionVFX;

	UPROPERTY(EditAnywhere)
	const float MaxLifetime = 5.0;

	UPROPERTY()
	FRocketExploded OnRocketExplodedEvent;

	UTargetableComponent HomingTarget;

	USkylineFlyingCarGunnerComponent GunnerComponent;

	FHazeAcceleratedFloat AcceleratedMeshScale;

	FVector BaseVelocity;
	FVector AimDirection;
	FHazeRange SpeedRange;
	float SpeedAccelerationDuration;

	float Damage;
	float AirTime;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		TrailNiagaraComponent.DeactivateImmediately();
	}

	void Launch(FBazookaRocketLaunchParams LaunchParams)
	{
		Damage = LaunchParams.Damage;
		HomingTarget = LaunchParams.HomingTarget;
		BaseVelocity = LaunchParams.BaseVelocity;
		AimDirection = LaunchParams.AimDirection;
		SpeedRange = LaunchParams.SpeedRange;
		SpeedAccelerationDuration = LaunchParams.SpeedAccelerationDuration;

		SetActorVelocity(BaseVelocity);
		SetActorRotation(FQuat::MakeFromX(LaunchParams.AimDirection));

		SetActorTickEnabled(true);
		Root.SetVisibility(true, true);

		AirTime = 0;
		AcceleratedMeshScale.SnapTo(0.1);

		USkylineFlyingCarBazookaRocketEventHandler::Trigger_RocketLaunched(this);

		TrailNiagaraComponent.Activate(true);

		OnRocketLaunched(LaunchParams);
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaTime)
	{
		float SpeedFraction = Math::Saturate(AirTime / SpeedAccelerationDuration);
		float Speed = SpeedRange.Lerp(Math::Pow(SpeedFraction, 3));
		FVector Velocity = BaseVelocity + AimDirection * Speed;

		if (HomingTarget != nullptr)
		{
			float TimeMultiplier = Math::Pow(Math::Saturate(AirTime / 0.2), 3);
			FVector RocketToTarget = (HomingTarget.WorldLocation - ActorLocation).GetSafeNormal();
			Velocity = Velocity.RotateTowards(RocketToTarget, 40.0 * TimeMultiplier);

			Print("Homing towards " + HomingTarget.Owner.Name, 0);
		}

		SetActorVelocity(Velocity);

		FVector NextLocation = ActorLocation + ActorVelocity * DeltaTime;
		SetActorLocation(NextLocation);

		FQuat Rotation = Math::QInterpTo(ActorQuat, FQuat::MakeFromX(ActorVelocity), DeltaTime, 10);
		SetActorRotation(Rotation);

		// Eman TODO: Rofl test scale mesh
		AcceleratedMeshScale.SpringTo(2.0, 200, 0.2,  DeltaTime);
		float Scale = Math::Max(0.1, AcceleratedMeshScale.Value);
		MeshComponent.SetRelativeScale3D(FVector(Scale));

		if (HasControl())
		{
			FHazeTraceSettings Trace = Trace::InitFromPrimitiveComponent(CollisionCapsule);
			Trace.IgnorePlayers();
			FOverlapResultArray Overlaps = Trace.QueryOverlaps(ActorLocation);
			for (auto Overlap : Overlaps)
			{
				if (Overlap.Actor.IsA(ASkylineFlyingCar))
					continue;

				if (Overlap.bBlockingHit)
				{
					if (Overlap.Actor == nullptr)
						continue;

					auto BazookaResponseComponent = USkylineFlyingCarBazookaResponseComponent::Get(Overlap.Actor);
					if (BazookaResponseComponent != nullptr)
					{
						FVector ImpactPoint;
						Overlap.Component.GetClosestPointOnCollision(ActorLocation, ImpactPoint);
						FVector ImpulseNormal = (ImpactPoint - ActorLocation).GetSafeNormal();

						if(ImpulseNormal.IsNearlyZero())
						{
							ImpulseNormal = (Overlap.Component.BoundsOrigin - ActorLocation).GetSafeNormal();
							if(ImpulseNormal.IsNearlyZero())
								ImpulseNormal = Velocity.GetSafeNormal();
						}
						
						BazookaResponseComponent.OnHit.Broadcast(ImpactPoint, ImpulseNormal);
					}

					FHitResult BullshitHitResult;
					BullshitHitResult.Actor = Overlap.Actor;
					BasicAIProjectile::DealDamage(BullshitHitResult, Damage, EDamageType::Projectile, this, FPlayerDeathDamageParams(ActorLocation, 0.1));

					Print("BAM!", 1);
					Explode();
					break;
				}
			}
		}

		AirTime += DeltaTime;
		if (AirTime > MaxLifetime)
			Explode();
	}

	void Explode()
	{
		// "Turn off" rocket
		ActorVelocity = FVector::ZeroVector;
		SetActorTickEnabled(false);
		//Root.SetVisibility(false, true);

		TrailNiagaraComponent.DeactivateImmediately();

		USkylineFlyingCarBazookaRocketEventHandler::Trigger_RocketImpact(this);

		// Spawn vfx
		if (ExplosionVFX != nullptr)
			Niagara::SpawnOneShotNiagaraSystemAtLocation(ExplosionVFX, ActorLocation, ActorRotation);

		// Let pool know we're done
		OnRocketExplodedEvent.Broadcast(this);
		OnRocketExploded();
	}

// TEMP VFX SHIET
	UFUNCTION(BlueprintEvent)
	void OnRocketLaunched(FBazookaRocketLaunchParams LaunchParams) { }

	UFUNCTION(BlueprintEvent)
	void OnRocketExploded() { }
// TEMP VFX SHIET

}

class USkylineFlyingCarBazookaRocketEventHandler : UHazeEffectEventHandler
{
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void RocketLaunched() { }

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void RocketImpact() { }

}