enum ECoastTrainDroneProjectileType
{
	Disc,
	Propeller,
	Pump,
	MAX
}

class ACoastTrainDroneProjectile : AHazeActor
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
	ECoastTrainDroneProjectileType Type = ECoastTrainDroneProjectileType::Propeller;	

	UCoastTrainDroneSettings DroneSettings;
	float AngleRotation;
	FRotator Rotation;
	FHazeAcceleratedFloat RotationSpeed;
	float BoloTargetDistance;
	bool BoloContract = false;
	FHazeAcceleratedFloat BoloDistance;

	FVector LocalVelocity;
	FVector Mesh1PreviousLocation;
	FVector Mesh2PreviousLocation;
	
	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		ProjectileComp.OnLaunch.AddUFunction(this, n"OnLaunch");
	}

	UFUNCTION()
	private void OnLaunch(UBasicAIProjectileComponent Projectile)
	{
		DroneSettings = UCoastTrainDroneSettings::GetSettings(Projectile.Launcher);
		Mesh.SetRelativeLocation(FVector(-DroneSettings.ProjectileBoloMinDistance/2, 0, 0));
		Mesh2.SetRelativeLocation(FVector(DroneSettings.ProjectileBoloMinDistance/2, 0, 0));
		BoloDistance.SnapTo(DroneSettings.ProjectileBoloSpawnDistance);
		RotationSpeed.SnapTo(DroneSettings.ProjectileStartRotationSpeed);
		BoloTargetDistance = DroneSettings.ProjectileBoloMaxDistance;
	}

	// Projectile will start ticking when launched and will be disabled when it expires
	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaTime)
	{
		if (!ProjectileComp.bIsLaunched)
			return;

		// Local movement, should be deterministic(ish)
		FHitResultArray Hits;
		UpdateVelocity(DeltaTime);
		SetActorLocation(GetUpdatedMovementLocation(DeltaTime, Hits));
		if (Hits.HasBlockHits())
		{
			for(FHitResult Hit: Hits.HitResults)
			{
				OnImpact(Hit);
				Impact(Hit);
			}
		}

		FVector Dir = ProjectileComp.Velocity.GetSafeNormal();
		FVector Up = Dir.CrossProduct(FVector::UpVector).CrossProduct(Dir);

		RotationSpeed.AccelerateTo(200, 0.5, DeltaTime);
		AngleRotation += DeltaTime * RotationSpeed.Value;

		if(Type == ECoastTrainDroneProjectileType::Propeller)
			SetActorRotation(Up.RotateAngleAxis(AngleRotation, Dir).Rotation());
		if(Type == ECoastTrainDroneProjectileType::Disc)
			SetActorRotation(Dir.RotateAngleAxis(AngleRotation, Up).Rotation());

		float Stiffness = 1;
		if(Type == ECoastTrainDroneProjectileType::Pump)
		{
			SetActorRotation(Dir.CrossProduct(FVector::UpVector).Rotation());
			Stiffness = 20;

			if(BoloContract && BoloDistance.Value < DroneSettings.ProjectileBoloMinDistance + 10)
			{
				BoloContract = false;
				BoloTargetDistance = DroneSettings.ProjectileBoloMaxDistance;
			}
			else if(!BoloContract && BoloDistance.Value > DroneSettings.ProjectileBoloMaxDistance - 10)
			{
				BoloContract = true;
				BoloTargetDistance = DroneSettings.ProjectileBoloMinDistance;
			}
		}

		BoloDistance.SpringTo(BoloTargetDistance, Stiffness, 0.1, DeltaTime);
		Mesh.SetRelativeLocation(FVector(-BoloDistance.Value/2, 0, 0));
		Mesh2.SetRelativeLocation(FVector(BoloDistance.Value/2, 0, 0));

		Beam.SetNiagaraVariableVec3("BeamStart", Mesh.RelativeLocation);
		Beam.SetNiagaraVariableVec3("BeamEnd", Mesh2.RelativeLocation);

		if (Time::GetGameTimeSince(ProjectileComp.LaunchTime) > ExpirationTime)
			ProjectileComp.Expire();

		Mesh1PreviousLocation = Mesh.WorldLocation;
		Mesh2PreviousLocation = Mesh2.WorldLocation;
	}

	void Impact(FHitResult Hit)
	{
		if (Hit.Actor != nullptr)
		{
			auto Player = Cast<AHazePlayerCharacter>(Hit.Actor);
			if(Player != nullptr)
			{
#if TEST
				if(Player.GetGodMode() == EGodMode::God)
					return;
#endif

				if(AttachParentActor == nullptr)
					return;

				ACoastTrainCart TrainCart = Cast<ACoastTrainCart>(AttachParentActor);
				if(TrainCart == nullptr)
					return;

				UTrainPlayerLaunchOffComponent LaunchComp = UTrainPlayerLaunchOffComponent::GetOrCreate(Player);

				// Launch relative to train, but switch side sign depending on player position
				FVector LaunchForceLocal = DroneSettings.ProjectileImpulseForce;
				if (TrainCart.ActorRightVector.DotProduct(Player.ActorLocation - TrainCart.ActorLocation) < 0.0)
					LaunchForceLocal.Y *= -1.0;

				FTrainPlayerLaunchParams Launch;
				Launch.LaunchFromCart = TrainCart;
				Launch.ForceDuration = DroneSettings.ProjectileImpulseDuration;
				Launch.FloatDuration = DroneSettings.ProjectileImpulseFloatDuration;
				Launch.PointOfInterestDuration = DroneSettings.ProjectileImpulseFloatDuration;
				Launch.Force = TrainCart.ActorTransform.TransformVectorNoScale(LaunchForceLocal);
				LaunchComp.TryLaunch(Launch);
			}
		}
	}

	void UpdateVelocity(float DeltaTime)
	{
		LocalVelocity -= ProjectileComp.UpVector * ProjectileComp.Gravity * DeltaTime;
		LocalVelocity -= LocalVelocity * ProjectileComp.Friction * DeltaTime;
		ProjectileComp.Velocity = AttachParentActor.ActorTransform.TransformVectorNoScale(LocalVelocity);
	}

	// Helper function for simple trace projectiles
	FVector GetUpdatedMovementLocation(float DeltaTime, FHitResultArray& OutHit)
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
		Trace.DebugDraw(0.01);
		OutHit = Trace.QueryTraceMulti(Mesh.WorldLocation, Mesh2.WorldLocation);

		float MinTime = BIG_NUMBER;
		bool bHit1 = false;
		bool bHit2 = false;
		for(auto Hit: OutHit.HitResults)
		{
			if(!Hit.bBlockingHit)
				continue;

			if(Hit.Location.IsWithinDist(Mesh.WorldLocation, Mesh.BoundsRadius))
			{
				bHit1 = true;
				MinTime = Math::Min(Hit.Time, MinTime);
			}
			if(Hit.Location.IsWithinDist(Mesh2.WorldLocation, Mesh2.BoundsRadius))
			{
				bHit2 = true;
				MinTime = Math::Min(Hit.Time, MinTime);
			}
		}

		if(bHit1 && bHit2)
		{
			ProjectileComp.Expire();
			return OwnLoc + Delta * MinTime;
		}

		return OwnLoc + Delta;
	}

	// Impact
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnImpact(FHitResult Hit) {}
}
