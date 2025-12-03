UCLASS(Abstract)
class ASanctuaryGrimbeastBoulderProjectile : AHazeActor
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
	USanctuaryGrimbeastProjectileResponseComponent RespondToIceComp;

	UPROPERTY(DefaultComponent)
	USanctuaryLavaApplierComponent LavaComp;
	default LavaComp.DamagePerSecond = 3.0;

	UPROPERTY()
	UNiagaraSystem HitEnvironmentEffect;

	// After this time we automatically expire
	UPROPERTY()
	float ExpirationTime = 15.0;

	AHazeActor Owner;
	FVector AttackLocation;

	float UpdateGravityTimer = 0.0;

	FRotator RollingRot;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		ProjectileComp.OnLaunch.AddUFunction(this, n"OnLaunch");
		RespondToIceComp.OnProjectileHit.AddUFunction(this, n"OnIceHit");
	}

	UFUNCTION()
	private void OnLaunch(UBasicAIProjectileComponent Projectile)
	{
		USanctuaryGrimbeastBoulderProjectileEventHandler::Trigger_OnLaunch(this, FSanctuaryGrimbeastBoulderProjectileOnLaunchEventData(AttackLocation));
	}

	UFUNCTION()
	private void OnIceHit(AActor OtherActor)
	{
		Niagara::SpawnOneShotNiagaraSystemAtLocation(HitEnvironmentEffect, ActorLocation);
		ProjectileComp.Expire();
	}

	// Projectile will start ticking when launched and will be disabled when it expires
	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaTime)
	{
		if (!ProjectileComp.bIsLaunched)
			return;

		FHitResult Hit;
		SetActorLocation(ProjectileComp.GetUpdatedMovementLocation(DeltaTime, Hit));
		SetActorRotation(ProjectileComp.Velocity.GetSafeNormal2D().Rotation());

		UpdateGravity(DeltaTime);

		// Debug::DrawDebugString(ActorLocation, "Gravity " + ProjectileComp.Gravity);
		// Debug::DrawDebugCoordinateSystem(ActorLocation, ActorRotation, 200.0);
		// Debug::DrawDebugSphere(ActorLocation, 90);

		LavaComp.ManualEndOverlapWholeCentipedeApply();
		bool bHit = false;
		for(FVector Location: GetBodyLocations())
		{
			if(!ActorLocation.IsWithinDist(Location, 90))
				continue;
			LavaComp.OverlapSingleFrame(Location, 90, false);
			bHit = true;
		}

		if (Hit.bBlockingHit || bHit)
		{
			ProjectileComp.Expire();
			USanctuaryGrimbeastBoulderProjectileEventHandler::Trigger_OnHit(this, FSanctuaryGrimbeastBoulderProjectileOnHitEventData(Hit));
			if (Hit.bBlockingHit && HitEnvironmentEffect != nullptr)
				Niagara::SpawnOneShotNiagaraSystemAtLocation(HitEnvironmentEffect, ActorLocation);
			if (Hit.Actor != nullptr)
			{
				auto ResponseComp = USanctuaryGrimbeastProjectileResponseComponent::Get(Hit.Actor);
				if (ResponseComp != nullptr)
					ResponseComp.OnProjectileHit.Broadcast(this);
			}
		}

		if (Time::GetGameTimeSince(ProjectileComp.LaunchTime) > ExpirationTime)
			ProjectileComp.Expire();

		RollingRot.Pitch += -ProjectileComp.Velocity.Size() * DeltaTime * 0.5;
		Mesh.SetRelativeRotation(RollingRot);
	}

	void UpdateGravity(float DeltaTime)
	{
		UpdateGravityTimer -= DeltaTime;
		if (UpdateGravityTimer < 0.0)
		{
			UpdateGravityTimer = Math::RandRange(0.05, 0.15); // spread out on frames
			FHazeTraceSettings Trace = Trace::InitChannel(ProjectileComp.TraceType);
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
			auto GroundHit = Trace.QueryTraceSingle(ActorLocation, ActorLocation - FVector::UpVector * 100.0);
			ProjectileComp.UpVector = FVector::UpVector;
			ProjectileComp.Gravity = GroundHit.bBlockingHit ? 0.0 : 982.0 ;
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