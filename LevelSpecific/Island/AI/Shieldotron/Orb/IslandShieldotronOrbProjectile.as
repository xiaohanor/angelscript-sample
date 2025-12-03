class UIslandShieldotronOrbLauncher : UBasicAIProjectileLauncherComponent
{
}

class AIslandShieldotronOrbProjectile : AHazeActor
{
	default PrimaryActorTick.bStartWithTickEnabled = false;

	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent)
	UStaticMeshComponent Mesh;
	default Mesh.CollisionProfileName = n"NoCollision";
	default Mesh.bCanEverAffectNavigation = false;

	UPROPERTY(DefaultComponent)
	USphereComponent ExplosionRange;

	UPROPERTY(DefaultComponent)
	UBasicAIProjectileComponent ProjectileComp;
	default ProjectileComp.Friction = 0.0;
	default ProjectileComp.Gravity = 0.0;

	UPROPERTY(DefaultComponent)
	UIslandShieldotronHomingProjectileComponent HomingProjectileComp;

	UPROPERTY(DefaultComponent)
	UHazeActorRespawnableComponent RespawnComp;

	// After this time we automatically expire
	UPROPERTY()
	float ExpirationTime = 6.0;

	// Optional
	float InitialLaunchSpeed = 0.0;

	float MaxSpeed = 0.0;
	float ReducedExpirationTime = 1.0;
	float ScaleTime = 0.0;
	float PrimeScaleTime = 6.0;
	float MaxPlanarHomingSpeed = 1000.0;

	bool bHasReducedExpirationTime = false;
	bool bShouldStopHomingWhenPassed = false;
	float DefaultFriction;
	AHazeActor Target;
	float HomingStrength;

	UIslandShieldotronSettings Settings;

	FVector LaunchDir2D;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		RespawnComp.OnRespawn.AddUFunction(this, n"OnReset");
		HomingProjectileComp = UIslandShieldotronHomingProjectileComponent::Get(this);
		DefaultFriction = ProjectileComp.Friction;
		
		ScaleTime = ExpirationTime;

		ProjectileComp.OnPrime.AddUFunction(this, n"OnPrime");
		ProjectileComp.OnLaunch.AddUFunction(this, n"OnLaunch");
	}
	
	UFUNCTION()
	private void OnPrime(UBasicAIProjectileComponent Projectile)
	{
		Settings = UIslandShieldotronSettings::GetSettings(Projectile.Launcher);

		HomingStrength = Settings.RocketHomingStrength;
		bShouldStopHomingWhenPassed = Settings.bHomingStopWhenPassed;
		MaxSpeed = Settings.AttackProjectileSpeed;
		InitialLaunchSpeed = MaxSpeed;
		
		FIslandShieldotronOrbProjectileOnPrimeData Params;
		auto Weapon = UBasicAIProjectileLauncherComponent::Get(Projectile.Launcher);
		Params.MuzzleLocation = Weapon.WorldLocation;
		Params.PrimeTime = Time::GameTimeSeconds;
		Params.LifeTime = PrimeScaleTime;
		UIslandShieldotronOrbProjectileEffectHandler::Trigger_OnPrime(this, Params);
	}

	UFUNCTION()
	private void OnLaunch(UBasicAIProjectileComponent Projectile)
	{
		LaunchDir2D = Projectile.Velocity.GetSafeNormal2D();
		auto Weapon = UBasicAIProjectileLauncherComponent::Get(Projectile.Launcher);
		FIslandShieldotronOrbProjectileOnLaunchData Params;
		Params.MuzzleLocation = Weapon.WorldLocation;
		Params.LaunchTime = Time::GameTimeSeconds;
		Params.LifeTime = ScaleTime;
		UIslandShieldotronOrbProjectileEffectHandler::Trigger_OnLaunch(this, Params);
		//PrevLocation = FVector::ZeroVector;
	}



	UFUNCTION()
	private void OnReset()
	{
		ProjectileComp.TraceType = ETraceTypeQuery::WeaponTraceEnemy;
		bHasReducedExpirationTime = false;
		Target = nullptr;
	}

	//FVector PrevLocation;
	// Projectile will start ticking when launched and will be disabled when it expires
	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaTime)
	{
		if (!ProjectileComp.bIsLaunched)
			return;
		
		float LaunchDuration = Time::GetGameTimeSince(ProjectileComp.LaunchTime);
		
		if (ProjectileComp.Launcher != nullptr && HomingProjectileComp != nullptr)
		{
			FVector TargetLocation = Target.ActorCenterLocation;
			if (ShouldStopHoming(TargetLocation))
			{				
				// Gradually reduce homingstrenght
				HomingStrength -= DeltaTime * HomingStrength;
				
				// Check if expiration time has to be cut.
				if (!bHasReducedExpirationTime)
				{
					float RemainingLifeTime = ExpirationTime - LaunchDuration;
					if (RemainingLifeTime > ReducedExpirationTime)
					{
						ProjectileComp.LaunchTime = Time::GetGameTimeSeconds(); // Shortening lifetime
						LaunchDuration = Time::GetGameTimeSince(ProjectileComp.LaunchTime);
						bHasReducedExpirationTime = true;
					}
				}
			}
			else
			{
				FVector PlaneNormal = ProjectileComp.Velocity.GetSafeNormal();								
				FVector PlanarHomingVelocity = HomingProjectileComp.GetPlanarHomingAcceleration(TargetLocation, PlaneNormal, HomingStrength) * DeltaTime;
				float MaxPlanarHomingSpeedDelta = MaxPlanarHomingSpeed * DeltaTime;
				PlanarHomingVelocity = PlanarHomingVelocity.Size() > MaxPlanarHomingSpeedDelta ? PlanarHomingVelocity.GetSafeNormal() * MaxPlanarHomingSpeedDelta : PlanarHomingVelocity;
				ProjectileComp.Velocity += PlanarHomingVelocity;
				//Debug::DrawDebugPoint(ActorLocation, 2.0, FLinearColor::Red, 3.0);				
			}
		}

		if (InitialLaunchSpeed > MaxSpeed)
		{
			// Cap to max velocity by deceleration
			float CurrentSpeed = ProjectileComp.Velocity.Size();
			if (CurrentSpeed > MaxSpeed)
			{
				float SpeedDiff = CurrentSpeed - MaxSpeed;
				float DecelerationFactor = 5;
				CurrentSpeed = Math::Max(MaxSpeed, CurrentSpeed - SpeedDiff * DecelerationFactor * DeltaTime);
				ProjectileComp.Velocity = ProjectileComp.Velocity.GetSafeNormal() * CurrentSpeed;
			}
		}
		else
		{
			// Constant speed
			ProjectileComp.Velocity = ProjectileComp.Velocity.GetSafeNormal() * MaxSpeed;
		}

		LocalMovement(DeltaTime);
		
		//if (PrevLocation.Size() > 0.1)
		//	Debug::DrawDebugLine(PrevLocation, ActorLocation, FLinearColor::Red, 1, 3.0);
		//PrevLocation = ActorLocation;	
		
		if (bHasReducedExpirationTime && LaunchDuration > ReducedExpirationTime)
		{
			Expire(FHitResult());
		}
		else if (LaunchDuration > ExpirationTime)
		{
			Expire(FHitResult());
		}
	}

	bool ShouldStopHoming(FVector TargetLocation)
	{	
		if (!bShouldStopHomingWhenPassed)
			return false;

		float LaunchDuration = Time::GetGameTimeSince(ProjectileComp.LaunchTime);
		if (LaunchDuration < 1.0)
			return false;

		if (HomingProjectileComp.bUseJetpackFriendlyHoming)
		{
			float ForwardDotProduct = ActorForwardVector.DotProduct((TargetLocation - ActorLocation).GetSafeNormal());
			float VerticalDotProduct = Math::Abs(ActorForwardVector.DotProduct(FVector::UpVector));
			if (ForwardDotProduct  < 0.83 || VerticalDotProduct > 0.98) // about 34 degrees from forward and 11.5 degrees from straight up or down)
			{
				return true;
			}			
		}
		else
		{
			// Velocity-based condition
			// if (ProjectileComp.Velocity.DotProduct((TargetLocation - ActorLocation).GetSafeNormal()) < Math::Cos(Math::DegreesToRadians(45)))
			// {
			// 	return true;
			// }

			// Offside-based condition
			FVector ToTarget2D = (TargetLocation - ActorLocation).GetSafeNormal2D();
			if (LaunchDir2D.DotProduct(ToTarget2D) < 0)
			{
				return true;
			}
		}

		return false;
	}

	void LocalMovement(float DeltaTime)
	{
		// Local movement, should be deterministic(ish)
		FHitResult Hit;
		SetActorLocation(ProjectileComp.GetUpdatedMovementLocation(DeltaTime, Hit));
		SetActorRotation(ProjectileComp.Velocity.Rotation());

		if (Hit.bBlockingHit)
			Expire(Hit);
	}

	void Expire(FHitResult Hit)
	{		
		FIslandShieldotronOrbProjectileOnImpactData Params;
		Params.HitResult = Hit;
		UIslandShieldotronOrbProjectileEffectHandler::Trigger_OnImpact(this, Params);
		Explode(Hit);
	}
	
	void Explode(FHitResult Hit)
	{
		FHazeTraceSettings Trace = Trace::InitChannel(ProjectileComp.TraceType);
		Trace.UseSphereShape(ExplosionRange);
		if (ProjectileComp.Launcher != nullptr)
			Trace.IgnoreActor(ProjectileComp.Launcher);
		FOverlapResultArray Overlaps = Trace.QueryOverlaps(ActorLocation);

#if EDITOR
		if (ProjectileComp.Launcher != nullptr)
		{
			//ProjectileComp.Launcher.bHazeEditorOnlyDebugBool = true;
			if (ProjectileComp.Launcher.bHazeEditorOnlyDebugBool) 				
				Debug::DrawDebugShape(ExplosionRange.GetCollisionShape(), ActorLocation, FRotator::ZeroRotator, LineColor = FLinearColor::Red, Duration = 0.2);
		}
#endif

		for(FOverlapResult Overlap: Overlaps.BlockHits)
		{			
			Impact(Overlap, Hit.ImpactPoint);
		}

		FBasicAiProjectileOnImpactData Data;
		Data.HitResult = Hit;
		UBasicAIProjectileEffectHandler::Trigger_OnImpact(this, Data);
		ProjectileComp.Expire();
	}

	void Impact(FOverlapResult Overlap, FVector ExplosionLocation)
	{
		if (Overlap.Actor != nullptr)
		{
			AHazePlayerCharacter HitPlayer = Cast<AHazePlayerCharacter>(Overlap.Actor);
			if (HitPlayer != nullptr)
			{
				HitPlayer.DealTypedDamage(ProjectileComp.Owner, Settings.OrbDamagePlayer, EDamageEffectType::ElectricityImpact, EDeathEffectType::ElectricityImpact);
				
				FVector ImpactDir = (HitPlayer.ActorCenterLocation - ExplosionLocation).GetNormalized2DWithFallback(-HitPlayer.ActorForwardVector);
				if (ImpactDir.Size() < SMALL_NUMBER)
					ImpactDir = HitPlayer.ActorForwardVector * -1.0;
				HitPlayer.ApplyStumble(ImpactDir * 100.0, 0.5);
				
				// temp, prevent screen shake in sidescroller
				UPlayerMovementPerspectiveModeComponent PerspectiveComp = UPlayerMovementPerspectiveModeComponent::Get(HitPlayer);
				if (PerspectiveComp == nullptr || (PerspectiveComp != nullptr && PerspectiveComp.IsIn3DPerspective()))
				{
					FIslandShieldotronOrbProjectileOnPlayerImpactData OrbParams;
					OrbParams.Player = HitPlayer;
					OrbParams.ImpactDirection = ImpactDir;				
					UIslandShieldotronOrbProjectileEffectHandler::Trigger_OnPlayerImpact(this, OrbParams);
				
					// screen shake in OBP from rocket
					FIslandShieldotronRocketProjectileOnPlayerImpactData Params;
					Params.Player = HitPlayer;
					Params.ImpactDirection = ImpactDir;
					UIslandShieldotronRocketProjectileEffectHandler::Trigger_OnPlayerDamage(this, Params);
				}
			}
		}
	}
}