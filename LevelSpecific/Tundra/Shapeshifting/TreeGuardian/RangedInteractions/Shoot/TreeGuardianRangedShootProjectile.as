enum ETundraTreeGuardianRangedShootProjectileState
{
	InSpawner,
	LaunchedBySpawner,
	HeldByTreeGuardian,
	ShotByTreeGuardian
}

event void FTundraTreeGuardianRangedShootProjectile();
event void FTundraTreeGuardianRangedShootProjectileDespawn(ATundraTreeGuardianRangedShootProjectile Projectile);

UCLASS(Abstract)
class ATundraTreeGuardianRangedShootProjectile : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	UStaticMeshComponent Mesh;
	default Mesh.CollisionProfileName = n"NoCollision";

	UPROPERTY(DefaultComponent, Attach = Root)
	UStaticMeshComponent InternalMesh;
	default InternalMesh.CollisionProfileName = n"NoCollision";

	UPROPERTY(DefaultComponent, Attach = Root)
	USphereComponent Collision;
	default Collision.CollisionProfileName = n"BlockAllDynamic";

	UPROPERTY(DefaultComponent, Attach = Root)
	UTundraTreeGuardianRangedInteractionTargetableComponent TreeGuardianTargetComp;
	default TreeGuardianTargetComp.InteractionType = ETundraTreeGuardianRangedInteractionType::Shoot;
	default TreeGuardianTargetComp.AutoAimMaxAngle = 360;
	default TreeGuardianTargetComp.MinimumDistance = 300;

	UPROPERTY(DefaultComponent)
	UHazeCrumbSyncedActorPositionComponent SyncedActorPosition;
	default SyncedActorPosition.SyncRate = EHazeCrumbSyncRate::PlayerSynced;
	default SyncedActorPosition.SyncDetailLevel = EHazeActorPositionSyncDetailLevel::TransformOnly;

	UPROPERTY()
	FTundraTreeGuardianRangedShootProjectile OnTreeGuardianInteract;
	UPROPERTY()
	FTundraTreeGuardianRangedShootProjectileDespawn OnProjectileDespawn;

	ETundraTreeGuardianRangedShootProjectileState State = ETundraTreeGuardianRangedShootProjectileState::InSpawner;
	FHazeAcceleratedFloat AcceleratedScale;
	FHazeAcceleratedFloat AcceleratedGravity;
	FVector Velocity;
	FVector TargetLocation;
	UTundraTreeGuardianRangedShootTargetable TargetTargetable;
	UHazeActorNetworkedSpawnPoolComponent SpawnPool;

	const float UpwardsImpulse = 3500.0;
	const float MinGravityAcceleration = 2000.0;
	const float MaxGravityAcceleration = 4000.0;
	const float GravityAccelerationDuration = 4.0;
	const float ShootSpeed = 20000.0;
	const float MinDownwardsSpeed = -2000.0;

	const float ScaleUpDuration = 1.1;
	const float MinPulseScale = 2.4;
	const float MaxPulseScale = 2.55;
	const float PulseScaleSpeedMultiplier = 1.0;

	TOptional<float> SurfaceHeight;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		SetActorControlSide(Game::Zoe);
		TreeGuardianTargetComp.OnCommitInteract.AddUFunction(this, n"Internal_OnTreeGuardianInteract");
		TreeGuardianTargetComp.OnShootInteractLaunch.AddUFunction(this, n"OnTreeGuardianShoot");
		OnDespawn();
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaTime)
	{
		ActorScale3D = FVector(AcceleratedScale.AccelerateTo(1.0, ScaleUpDuration, DeltaTime));
		InternalMesh.RelativeScale3D = FVector(Math::Lerp(MinPulseScale, MaxPulseScale, (Math::Sin(Time::GetGameTimeSeconds() * PulseScaleSpeedMultiplier) + 1) * 0.5));

		if(SurfaceHeight.IsSet() && ActorLocation.Z >= SurfaceHeight.Value)
		{
			SurfaceHeight.Reset();
			UTundraTreeGuardianRangedShootProjectileVFXHandler::Trigger_OnBreakWaterSurface(this);
		}

		if(!HasControl())
		{
			if(RootComponent.AttachParent != nullptr)
				return;

			auto Position = SyncedActorPosition.GetPosition();
			ActorLocation = Position.WorldLocation;
			ActorRotation = Position.WorldRotation;
			return;
		}

		switch(State)
		{
			case ETundraTreeGuardianRangedShootProjectileState::InSpawner:
			{
				break;
			}
			case ETundraTreeGuardianRangedShootProjectileState::LaunchedBySpawner:
			{
				AcceleratedGravity.AccelerateTo(MinGravityAcceleration, GravityAccelerationDuration, DeltaTime);
				Velocity += FVector::DownVector * (AcceleratedGravity.Value * DeltaTime);
				ActorLocation += Velocity * DeltaTime;

				if(Velocity.DotProduct(FVector::UpVector) < MinDownwardsSpeed)
				{
					CrumbOnFailDespawn();
				}

				break;
			}
			case ETundraTreeGuardianRangedShootProjectileState::HeldByTreeGuardian:
			{
				break;
			}
			case ETundraTreeGuardianRangedShootProjectileState::ShotByTreeGuardian:
			{
				if(TargetTargetable != nullptr)
					TargetLocation = TargetTargetable.WorldLocation;

				FVector NextLocation = Math::VInterpConstantTo(ActorLocation, TargetLocation, DeltaTime, ShootSpeed);

				if(NextLocation.Equals(TargetLocation))
				{
					ActorLocation = NextLocation;
					TriggerImpact();
					return;
				}

				FVector Direction = (TargetLocation - ActorLocation).GetSafeNormal();
				FVector TraceOffsetDelta = Direction * Collision.SphereRadius;

				FHazeTraceSettings Trace = Trace::InitChannel(ECollisionChannel::WeaponTracePlayer);
				Trace.UseLine();
				Trace.IgnoreActor(this);
				Trace.UseShapeWorldOffset(TraceOffsetDelta);
				FHitResultArray Hits = Trace.QueryTraceMulti(ActorLocation, NextLocation);
				for(FHitResult Hit : Hits)
				{
					if(Hit.bStartPenetrating)
						continue;

					if(TargetTargetable != nullptr && Hit.Actor != TargetTargetable.Owner)
						continue;

					TriggerImpact();
					return;
				}

				ActorLocation = NextLocation;
				break;
			}
		}
	}

	void TriggerImpact()
	{
		if(!HasControl())
			return;

		CrumbTriggerImpact(TargetTargetable);
	}

	UFUNCTION(CrumbFunction)
	private void CrumbTriggerImpact(UTundraTreeGuardianRangedShootTargetable Targetable)
	{
		if(Targetable != nullptr)
			Targetable.OnHit.Broadcast();

		FTreeGuardianRangedShootProjectileImpactParams Params;
		Params.ProjectileLocation = ActorLocation;
		UTundraTreeGuardianRangedShootProjectileVFXHandler::Trigger_OnImpact(this, Params);
		OnDespawn();
	}

	UFUNCTION(CrumbFunction)
	private void CrumbOnFailDespawn()
	{
		FTreeGuardianRangedShootProjectileDespawnParams Params;
		Params.ProjectileLocation = ActorLocation;
		UTundraTreeGuardianRangedShootProjectileVFXHandler::Trigger_OnFailDespawn(this, Params);
		OnDespawn();
	}

	void OnDespawn()
	{
		AddActorDisable(this);
		TreeGuardianTargetComp.Disable(this);

		if(SpawnPool != nullptr)
			SpawnPool.UnSpawn(this);

		OnProjectileDespawn.Broadcast(this);
	}

	void LaunchBySpawner()
	{
		Velocity = FVector::UpVector * UpwardsImpulse;
		State = ETundraTreeGuardianRangedShootProjectileState::LaunchedBySpawner;
		AcceleratedGravity.SnapTo(MaxGravityAcceleration);
		TreeGuardianTargetComp.Enable(this);

		UTundraTreeGuardianRangedShootProjectileVFXHandler::Trigger_OnLaunched(this);
		SurfaceHeight.Reset();
		CalculateSurfaceHeight();
	}

	void CalculateSurfaceHeight()
	{
		FHazeTraceSettings Trace = Trace::InitProfile(n"PlayerCharacter");
		Trace.UseSphereShape(Collision.SphereRadius);
		FOverlapResultArray Overlaps = Trace.QueryOverlaps(Collision.WorldLocation);

		TArray<FOverlapResult> OverlapArray = Overlaps.GetOverlapHits();
		for(FOverlapResult Overlap : OverlapArray)
		{
			auto Current = Cast<ATundraIceSwimmingVolume>(Overlap.Actor);
			if(Current == nullptr)
				continue;

			FVector Point;
			Current.BrushComponent.GetClosestPointOnCollision(Collision.WorldLocation + FVector::UpVector * 1000.0, Point);
			SurfaceHeight = Point.Z;
			return;
		}
	}

	UFUNCTION()
	private void Internal_OnTreeGuardianInteract()
	{
		State = ETundraTreeGuardianRangedShootProjectileState::HeldByTreeGuardian;
		OnTreeGuardianInteract.Broadcast();

		auto TreeGuardianComp = UTundraPlayerTreeGuardianComponent::Get(Game::Zoe);
		FTreeGuardianRangedShootProjectileGrabbedParams Params;
		Params.bHasTarget = TreeGuardianComp.CurrentRangedShootTargetable != nullptr;
		UTundraTreeGuardianRangedShootProjectileVFXHandler::Trigger_OnGrabbedByTreeGuardian(this, Params);
	}

	UFUNCTION()
	private void OnTreeGuardianShoot(UTundraTreeGuardianRangedShootTargetable Targetable, FVector FallbackDirection)
	{
		UTundraTreeGuardianRangedShootProjectileVFXHandler::Trigger_OnThrownByTreeGuardian(this);

		if(!HasControl())
			return;

		State = ETundraTreeGuardianRangedShootProjectileState::ShotByTreeGuardian;
		TargetTargetable = Targetable;

		FVector TraceStart = ActorLocation;
		FVector TraceEnd = TraceStart + FallbackDirection * 10000.0;
		if(TargetTargetable != nullptr)
			TraceEnd = TargetTargetable.WorldLocation;

		FHazeTraceSettings Trace = Trace::InitChannel(ECollisionChannel::WeaponTracePlayer);
		Trace.UseSphereShape(Collision.SphereRadius);
		Trace.IgnorePlayers();
		Trace.IgnoreActor(this);
		FHitResultArray Hits = Trace.QueryTraceMulti(TraceStart, TraceEnd);
		for(FHitResult Hit : Hits.BlockHits)
		{
			if(Hit.bStartPenetrating)
				continue;

			if(TargetTargetable != nullptr && Hit.Actor != TargetTargetable.Owner)
				continue;

			if(Hit.bBlockingHit)
			{
				TargetLocation = Hit.Location;
			}
			else
			{
				TargetLocation = Hit.TraceEnd;
			}
		}
	}

	void Spawn(UHazeActorNetworkedSpawnPoolComponent In_SpawnPool)
	{
		SyncedActorPosition.TransitionSync(this);
		RemoveActorDisable(this);
		ActorScale3D = FVector(KINDA_SMALL_NUMBER);
		AcceleratedScale.SnapTo(KINDA_SMALL_NUMBER);
		State = ETundraTreeGuardianRangedShootProjectileState::InSpawner;
		SpawnPool = In_SpawnPool;
	}
}