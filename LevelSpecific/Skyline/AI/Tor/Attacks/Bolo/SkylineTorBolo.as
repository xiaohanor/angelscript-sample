enum ESkylineTorBoloType
{
	Disc,
	Propeller,
	Pump,
	PropellerReverse,
	MAX
}

class ASkylineTorBolo : AHazeActor
{
	default PrimaryActorTick.bStartWithTickEnabled = false;

	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent)
	UStaticMeshComponent Mesh;
	default Mesh.CollisionProfileName = n"NoCollision";
	default Mesh.bCanEverAffectNavigation = false;

	UPROPERTY(DefaultComponent)
	UStaticMeshComponent Mesh2;
	default Mesh.CollisionProfileName = n"NoCollision";
	default Mesh.bCanEverAffectNavigation = false;

	UPROPERTY(DefaultComponent)
	UNiagaraComponent Beam;

	UPROPERTY(DefaultComponent)
	UBasicAIProjectileComponent ProjectileComp;
	default ProjectileComp.Friction = 0.01;
	default ProjectileComp.Gravity = 9.82;

	UPROPERTY(DefaultComponent)
	UHazeActorRespawnableComponent RespawnComp;

	// After this time we automatically expire
	UPROPERTY()
	float ExpirationTime = 10.0;

	UPROPERTY()
	ESkylineTorBoloType Type = ESkylineTorBoloType::Propeller;	

	UPROPERTY()
	TSubclassOf<UDamageEffect> DamageEffect;

	UPROPERTY()
	TSubclassOf<UDeathEffect> DeathEffect;

	USkylineTorSettings Settings;
	float AngleRotation;
	FRotator Rotation;
	FHazeAcceleratedFloat RotationSpeed;
	float BoloTargetDistance;
	bool BoloContract = false;
	FHazeAcceleratedFloat BoloDistance;

	FVector LocalVelocity;
	FVector Mesh1PreviousLocation;
	FVector Mesh2PreviousLocation;

	bool bMeshDestroyed;
	bool bMesh2Destroyed;

	TArray<UNiagaraComponent> NiagaraComps;
	bool bNiagaraExpire;
	int NiagaraFinishedNum;
	
	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		ProjectileComp.OnLaunch.AddUFunction(this, n"OnLaunch");
		Mesh.AddComponentVisualsBlocker(this);
		Mesh2.AddComponentVisualsBlocker(this);

		Root.GetChildrenComponentsByClass(UNiagaraComponent, true, NiagaraComps);
		for(UNiagaraComponent Niagara : NiagaraComps)
			Niagara.OnSystemFinished.AddUFunction(this, n"SystemFinished");

		RespawnComp.OnRespawn.AddUFunction(this, n"Respawn");
	}

	UFUNCTION()
	private void SystemFinished(UNiagaraComponent PSystem)
	{
		NiagaraFinishedNum++;
	}

	UFUNCTION()
	private void Respawn()
	{
		bNiagaraExpire = false;
		NiagaraFinishedNum = 0;
	}

	UFUNCTION()
	private void OnLaunch(UBasicAIProjectileComponent Projectile)
	{
		Settings = USkylineTorSettings::GetSettings(Projectile.Launcher);
		Mesh.SetRelativeLocation(FVector(-Settings.BoloMinDistance/2, 0, 0));
		Mesh2.SetRelativeLocation(FVector(Settings.BoloMinDistance/2, 0, 0));
		BoloDistance.SnapTo(Settings.BoloSpawnDistance);
		RotationSpeed.SnapTo(Settings.BoloStartRotationSpeed);
		BoloTargetDistance = Settings.BoloMaxDistance;

		Mesh.RemoveComponentVisualsBlocker(this);
		Mesh2.RemoveComponentVisualsBlocker(this);
		bMeshDestroyed = false;
		bMesh2Destroyed = false;

		Beam.Activate();
	}

	// Projectile will start ticking when launched and will be disabled when it expires
	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaTime)
	{
		if (!ProjectileComp.bIsLaunched)
			return;
		if (bNiagaraExpire)
		{
			if(NiagaraFinishedNum < NiagaraComps.Num())
				return;
			ProjectileComp.Expire();
			return;
		}

		// Local movement, should be deterministic(ish)
		TArray<FHitResult> Hits;
		SetActorLocation(GetUpdatedMovementLocation(DeltaTime, Hits));
		for(FHitResult Hit: Hits)
		{
			Impact(Hit);
		}

		if(bMeshDestroyed && bMesh2Destroyed)
		{
			ParticleExpire();
			return;
		}

		FVector Dir = ProjectileComp.Velocity.GetSafeNormal();
		FVector Up = Dir.CrossProduct(FVector::UpVector).CrossProduct(Dir);

		RotationSpeed.AccelerateTo(300, 0.5, DeltaTime);
		AngleRotation += DeltaTime * RotationSpeed.Value;

		if(Type == ESkylineTorBoloType::Propeller)
			SetActorRotation(Up.RotateAngleAxis(AngleRotation, Dir).Rotation());
		if(Type == ESkylineTorBoloType::PropellerReverse)
			SetActorRotation(Up.RotateAngleAxis(-AngleRotation, Dir).Rotation());
		if(Type == ESkylineTorBoloType::Disc)
			SetActorRotation(Dir.RotateAngleAxis(AngleRotation, Up).Rotation());

		float Stiffness = 2;
		if(Type == ESkylineTorBoloType::Pump)
		{
			SetActorRotation(Dir.CrossProduct(FVector::UpVector).Rotation());
			Stiffness = 20;

			if(BoloContract && BoloDistance.Value < Settings.BoloMinDistance + 10)
			{
				BoloContract = false;
				BoloTargetDistance = Settings.BoloMaxDistance;
			}
			else if(!BoloContract && BoloDistance.Value > Settings.BoloMaxDistance - 10)
			{
				BoloContract = true;
				BoloTargetDistance = Settings.BoloMinDistance;
			}
		}

		BoloDistance.SpringTo(BoloTargetDistance, Stiffness, 0.1, DeltaTime);
		Mesh.SetRelativeLocation(FVector(-BoloDistance.Value/2, 0, 0));
		Mesh2.SetRelativeLocation(FVector(BoloDistance.Value/2, 0, 0));

		Beam.SetNiagaraVariableVec3("BeamStart", Mesh.RelativeLocation);
		Beam.SetNiagaraVariableVec3("BeamEnd", Mesh2.RelativeLocation);

		if (Time::GetGameTimeSince(ProjectileComp.LaunchTime) > ExpirationTime)
			ParticleExpire();

		Mesh1PreviousLocation = Mesh.WorldLocation;
		Mesh2PreviousLocation = Mesh2.WorldLocation;
	}

	private void ParticleExpire()
	{
		bNiagaraExpire = true;
		for(UNiagaraComponent Niagara : NiagaraComps)
			Niagara.Deactivate();
	}

	void Impact(FHitResult Hit)
	{
		if (Hit.Actor != nullptr)
		{
			auto Player = Cast<AHazePlayerCharacter>(Hit.Actor);
			if(Player != nullptr)
			{
				Player.DamagePlayerHealth(0.5, DamageEffect = DamageEffect, DeathEffect = DeathEffect);
			}
		}
	}

	// Helper function for simple trace projectiles
	FVector GetUpdatedMovementLocation(float DeltaTime, TArray<FHitResult>& OutHits)
	{
		FVector OwnLoc = ActorLocation;
		
		FVector Delta = ProjectileComp.Velocity * DeltaTime;
		if (Delta.IsNearlyZero())
			return OwnLoc;

		FHazeTraceSettings Trace = Trace::InitChannel(ProjectileComp.TraceType);
		Trace.IgnoreActor(this, false);
		Trace.UseCapsuleShape(24, 24, FQuat::Identity);
		Trace.IgnoreActors(ProjectileComp.AdditionalIgnoreActors);

		if (ProjectileComp.Launcher != nullptr)
		{	
			Trace.IgnoreActor(ProjectileComp.Launcher);
		}

		FHitResultArray Hits = Trace.QueryTraceMulti(Mesh.WorldLocation, Mesh2.WorldLocation);
		for(FHitResult Hit : Hits.HitResults)
		{
			if(Hit.bBlockingHit)
				OutHits.Add(Hit);
		}

		if(!bMeshDestroyed)
		{
			FHitResult Hit = Trace.QueryTraceSingle(Mesh.WorldLocation, Mesh.WorldLocation + Delta);
			if(Hit.bBlockingHit)
			{
				OutHits.Add(Hit);
				bMeshDestroyed = true;
				Mesh.AddComponentVisualsBlocker(this);
				Beam.Deactivate();
				USkylineTorBoloEventHandler::Trigger_OnImpact(this, FSkylineTorBoloEventHandlerOnImpactData(Hit.Location, true));
			}
		}

		if(!bMesh2Destroyed)
		{
			FHitResult Hit = Trace.QueryTraceSingle(Mesh2.WorldLocation, Mesh2.WorldLocation + Delta);
			if(Hit.bBlockingHit)
			{
				OutHits.Add(Hit);
				bMesh2Destroyed = true;
				Mesh2.AddComponentVisualsBlocker(this);
				Beam.Deactivate();
				USkylineTorBoloEventHandler::Trigger_OnImpact(this, FSkylineTorBoloEventHandlerOnImpactData(Hit.Location, false));
			}
		}

		return OwnLoc + Delta;
	}
}