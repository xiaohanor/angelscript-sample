UCLASS(Abstract)
class ASanctuaryLavaMomBoulderProjectile : AHazeActor
{
	default PrimaryActorTick.bStartWithTickEnabled = false;

	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent)
	UStaticMeshComponent Mesh;
	default Mesh.CollisionProfileName = n"NoCollision";
	default Mesh.bCanEverAffectNavigation = false;

	UPROPERTY(DefaultComponent)
	UBasicAIProjectileComponent ProjectileComp;
	default ProjectileComp.Friction = 0.01;
	default ProjectileComp.Gravity = 9.82;

	UPROPERTY(DefaultComponent)
	UHazeActorRespawnableComponent RespawnComp;

	UPROPERTY(DefaultComponent)
	USanctuaryLavaApplierComponent LavaComp;
	default LavaComp.DamagePerSecond = 0.25;
	default LavaComp.DamageDuration = 1.0;

	UPROPERTY()
	UNiagaraSystem HitEnvironmentEffect;

	// After this time we automatically expire
	UPROPERTY()
	float ExpirationTime = 20.0;

	AHazeActor Owner;
	FVector AttackLocation;

	float UpdateGravityTimer = 0.0;
	float GroundSpeed = 0.0;

	FRotator RollingRot;

	bool bGrounded = false;
	FHazeAcceleratedFloat RollingSpeed;
	float HitRadius = 130.0;
	float OriginalHitRadius = 130.0;

	TArray<ASanctuaryLavaRubble> LavaRubbles;
	bool bBigBoulder = false;

	float OriginalDamagePerSecond = 0.0;
	bool bHitCentipede = false;
	bool bActive = false;
	float ActiveTimer = 0.0;

	FHazeAcceleratedFloat AccScale;

	const float TinyScale = 0.001;
	UPROPERTY(Category = "Attack|Boulder")
	float SmallBoulderScale = 0.7;
	UPROPERTY(Category = "Attack|Boulder")
	float BigBoulderScale = 1.7;
	UPROPERTY(Category = "Attack|Boulder")
	float BoulderScalingDuration = 3.0;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		ProjectileComp.OnLaunch.AddUFunction(this, n"OnLaunch");
		ProjectileComp.OnPrime.AddUFunction(this, n"OnPrime");
		OriginalDamagePerSecond = LavaComp.DamagePerSecond;
		OriginalHitRadius = HitRadius;
		AccScale.SnapTo(TinyScale);
		SetActorScale3D(FVector::OneVector * TinyScale);
	}

	UFUNCTION()
	private void OnPrime(UBasicAIProjectileComponent Projectile)
	{
		bActive = true;
		ActiveTimer = 0.0;
		AccScale.SnapTo(TinyScale);
		SetActorScale3D(FVector::OneVector * TinyScale);
	}

	UFUNCTION()
	private void OnLaunch(UBasicAIProjectileComponent Projectile)
	{
		USanctuaryLavaMomBoulderProjectileEventHandler::Trigger_OnLaunch(this, FSanctuaryLavaMomBoulderProjectileOnLaunchEventData(AttackLocation));
		RollingSpeed.SnapTo(0.0);
		LavaComp.DamagePerSecond = bBigBoulder ? OriginalDamagePerSecond * 2.0 : OriginalDamagePerSecond;
	}

	private void Expire()
	{
		bActive = false;
		ProjectileComp.Expire();
		Niagara::SpawnOneShotNiagaraSystemAtLocation(HitEnvironmentEffect, ActorLocation);
	}

	UFUNCTION()
	private void OnIceHit(AActor OtherActor)
	{
		Expire();
	}

	// Projectile will start ticking when launched and will be disabled when it expires
	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaTime)
	{
		if (!bActive)
			return;
		ActiveTimer += DeltaTime;
		UpdateScale(DeltaTime);

		if (!ProjectileComp.bIsLaunched)
			return;

		bHitCentipede = false;

		FHitResult EnvHit;
		// SetActorLocation(ProjectileComp.GetUpdatedMovementLocation(DeltaTime, EnvHit));
		SetActorLocation(GetUpdatedMovementLocation(DeltaTime, EnvHit));
		SetActorRotation(ProjectileComp.Velocity.GetSafeNormal2D().Rotation());

		HitRadius = OriginalHitRadius * GetActorScale3D().Max * 1.2;

		if (EnvHit.Component != nullptr)
		{
			UCentipedeSegmentComponent CentipedePart = Cast<UCentipedeSegmentComponent>(EnvHit.Component);
			if (CentipedePart != nullptr)
			{
				LavaComp.OverlapSingleFrame(CentipedePart.WorldLocation, HitRadius, false);
				bHitCentipede = true;
			}
		}

		UpdateGravity(DeltaTime);

		// Debug::DrawDebugString(ActorLocation, "Grounded " + bGrounded);
		// Debug::DrawDebugString(ActorLocation, "Gravity " + ProjectileComp.Gravity);
		// Debug::DrawDebugString(ActorLocation, "\n\nVel " + ProjectileComp.Velocity);
		// Debug::DrawDebugCoordinateSystem(ActorLocation, ActorRotation, HitRadius * 2.0, 8.0);
		// Debug::DrawDebugSphere(ActorLocation, HitRadius, 12, ColorDebug::Lavender, 3.0, 0.0, true);

		if (bBigBoulder)
		{
			float HitRubbleRadius = HitRadius * 2.0;
			// Debug::DrawDebugSphere(ActorLocation, HitRubbleRadius, 12, ColorDebug::Magenta, 3.0, 0.0, true);
			if (LavaRubbles.IsEmpty())
			{
				TListedActors<ASanctuaryLavaRubble> Rubbles;
				LavaRubbles = Rubbles.GetArray();
			}
			for (auto Rubble : LavaRubbles)
			{
				if (Rubble.bHit)
					continue;
				if(ActorLocation.IsWithinDist(Rubble.ActorLocation, HitRubbleRadius))
					Rubble.HitByABoulder();
			}
		}

		LavaComp.ManualEndOverlapWholeCentipedeApply();
		for (FVector Location: GetBodyLocations())
		{
			if(!ActorLocation.IsWithinDist(Location, HitRadius))
				continue;

			LavaComp.OverlapSingleFrame(Location, HitRadius, false);
			bHitCentipede = true;
		}

		if (bHitCentipede || EnvHit.bBlockingHit)
		{
			Expire();
			USanctuaryLavaMomBoulderProjectileEventHandler::Trigger_OnHit(this, FSanctuaryLavaMomBoulderProjectileOnHitEventData(EnvHit));
		}

		if (Time::GetGameTimeSince(ProjectileComp.LaunchTime) > ExpirationTime)
			Expire();

		RollingSpeed.AccelerateTo(bGrounded ? 0.4 : 0.1, 0.5, DeltaTime);
		RollingRot.Pitch += -ProjectileComp.Velocity.Size() * DeltaTime * RollingSpeed.Value / Mesh.GetWorldScale().Max;
		Mesh.SetRelativeRotation(RollingRot);
	}

	private void UpdateScale(float DeltaTime)
	{
		// snowball whohoooieieee
		float ScaleTarget = SmallBoulderScale;
		if (bBigBoulder)
			ScaleTarget = BigBoulderScale;
		AccScale.AccelerateTo(ScaleTarget, BoulderScalingDuration, DeltaTime);
		SetActorScale3D(FVector::OneVector * AccScale.Value);
	}

	FVector GetUpdatedMovementLocation(float DeltaTime, FHitResult& OutEnvHit)
	{
		FVector Delta = FVector::ZeroVector;

		ProjectileComp.Velocity -= ProjectileComp.UpVector * ProjectileComp.Gravity * DeltaTime;
		ProjectileComp.Velocity -= ProjectileComp.Velocity * ProjectileComp.Friction * DeltaTime;
		Delta += ProjectileComp.Velocity * DeltaTime;

		if (Delta.IsNearlyZero())
			return ActorLocation;

		if (Time::GetGameTimeSince(ProjectileComp.LaunchTime) > 1.0)
		{
			FVector FrontLoc = ActorLocation + ActorForwardVector * HitRadius;
			FHazeTraceSettings Trace = Trace::InitChannel(ETraceTypeQuery::WorldGeometry);
			Trace.UseLine();
			Trace.IgnoreActor(this);
			if (ProjectileComp.Launcher != nullptr)
			{
				Trace.IgnoreActor(ProjectileComp.Launcher);
				if (ProjectileComp.Launcher.AttachParentActor != nullptr)
					Trace.IgnoreActor(ProjectileComp.Launcher.AttachParentActor);
			}

			OutEnvHit = Trace.QueryTraceSingle(FrontLoc, FrontLoc + Delta);
			if (OutEnvHit.bBlockingHit)
				return OutEnvHit.ImpactPoint - OutEnvHit.ImpactNormal * HitRadius;

			// Project along ground?
			FVector FutureLocation = ActorLocation + Delta;
			FVector FutureGroundLoc = FutureLocation - FVector::UpVector * HitRadius;
			FHitResult GroundHit = Trace.QueryTraceSingle(FutureLocation, FutureGroundLoc);
			if (GroundHit.bBlockingHit)
				return GroundHit.ImpactPoint + FVector::UpVector * HitRadius;
		}

		return ActorLocation + Delta;
	}

	void UpdateGravity(float DeltaTime)
	{
		UpdateGravityTimer -= DeltaTime;
		if (UpdateGravityTimer < 0.0)
		{
			bGrounded = false;
			UpdateGravityTimer = Math::RandRange(0.05, 0.15); // spread out on frames
			FHazeTraceSettings Trace = Trace::InitChannel(ETraceTypeQuery::WeaponTracePlayer);
			Trace.UseLine();
			Trace.IgnoreActors(ProjectileComp.AdditionalIgnoreActors);

			if (ProjectileComp.Launcher != nullptr)
			{	
				Trace.IgnoreActor(ProjectileComp.Launcher, ProjectileComp.bIgnoreDescendants);

				if (ProjectileComp.bIgnoreLauncherAttachParents)
				{
					AActor AttachParent = ProjectileComp.Launcher.AttachParentActor;
					while (AttachParent != nullptr)
					{
						Trace.IgnoreActor(AttachParent);
						AttachParent = AttachParent.AttachParentActor;
					}				
				}
			}
			FVector TraceStart = ActorLocation;
			FVector TraceEnd = ActorLocation - FVector::UpVector * HitRadius * 1.0;
			auto GroundHit = Trace.QueryTraceSingle(TraceStart, TraceEnd);
			ProjectileComp.UpVector = FVector::UpVector;
			ProjectileComp.Gravity = GroundHit.bBlockingHit ? 0.0 : 982.0 ;
			FLinearColor DebugColor = ColorDebug::Cyan;
			if (GroundHit.bBlockingHit)
			{
				DebugColor = ColorDebug::Ruby;
				bGrounded = true;
				ProjectileComp.Velocity = ProjectileComp.Velocity.GetSafeNormal2D() * GroundSpeed;
			}

			// Debug::DrawDebugArrow(TraceStart, TraceEnd, 5.0, DebugColor, 5.0, 0.0, true);
		}
	}

	private TArray<FVector> GetBodyLocations() const
	{
		TArray<FVector> Locations;
		UPlayerCentipedeComponent CentipedeComp = UPlayerCentipedeComponent::Get(Game::Mio);
		if(ensure(CentipedeComp != nullptr, "Can only target centipede players!"))
			Locations = CentipedeComp.GetBodyLocations();
		return Locations;
	}
}