class AIslandShieldotronRocketProjectile : AHazeActor
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
	default ProjectileComp.Friction = 0.01;
	default ProjectileComp.Gravity = 9.82;

	UPROPERTY(DefaultComponent)
	UIslandShieldotronHomingProjectileComponent HomingProjectileComp;

	UPROPERTY(DefaultComponent)
	UHazeActorRespawnableComponent RespawnComp;

	// After this time we automatically expire
	UPROPERTY()
	float ExpirationTime = 4.0;

	bool bStopHoming = false;
	bool bShouldStopHomingWhenPassed = false;
	float DefaultFriction;
	AHazeActor Target;
	FVector TargetGroundLocation = FVector::ZeroVector;
	float HomingStrength;

	UIslandShieldotronSettings Settings;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		RespawnComp.OnRespawn.AddUFunction(this, n"OnReset");
		HomingProjectileComp = UIslandShieldotronHomingProjectileComponent::Get(this);
		DefaultFriction = ProjectileComp.Friction;
		
		ProjectileComp.OnLaunch.AddUFunction(this, n"OnLaunch");
	}
	

	UFUNCTION()
	private void OnLaunch(UBasicAIProjectileComponent Projectile)
	{
		if (Projectile.Launcher != nullptr)
		{
			Settings = UIslandShieldotronSettings::GetSettings(Projectile.Launcher);
			
			auto Weapon = UBasicAIProjectileLauncherComponent::Get(Projectile.Launcher);
			FIslandShieldotronRocketProjectileOnLaunchData Params;
			Params.MuzzleLocation = Weapon.WorldLocation;
			UIslandShieldotronRocketProjectileEffectHandler::Trigger_OnLaunch(this, Params);
		}
		HomingStrength = Settings.RocketHomingStrength;
		bShouldStopHomingWhenPassed = Settings.bHomingStopWhenPassed;
	}

	UFUNCTION()
	private void OnReset()
	{
		ProjectileComp.TraceType = ETraceTypeQuery::WeaponTraceEnemy;
		bStopHoming = false;
		Target = nullptr;
		TargetGroundLocation = FVector::ZeroVector;
	}

	// Projectile will start ticking when launched and will be disabled when it expires
	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaTime)
	{
		if (!ProjectileComp.bIsLaunched)
			return;
		
		float LaunchDuration = Time::GetGameTimeSince(ProjectileComp.LaunchTime);
		if (ProjectileComp.Launcher != nullptr && HomingProjectileComp != nullptr && !bStopHoming)
		{
			// TODO: add optional target location instead of target actor to homing projectile comp.
			FVector TargetLocation = (Target != nullptr) ? Target.ActorCenterLocation : TargetGroundLocation;
			if ((TargetLocation.IsZero() && Target == nullptr) || ShouldStopHoming(TargetLocation))
			{
				bStopHoming = true;
			}
			else
			{
				ProjectileComp.Velocity += HomingProjectileComp.GetPlanarHomingAcceleration(TargetLocation, ProjectileComp.Velocity.GetSafeNormal(), HomingStrength) * DeltaTime;
			}			
		}

		// Cap to max velocity
		float CurrentSpeed = ProjectileComp.Velocity.Size();
		if (CurrentSpeed > Settings.AttackProjectileSpeed)
		{
			float SpeedDiff = CurrentSpeed - Settings.AttackProjectileSpeed;
			float Acceleration = 10;
			CurrentSpeed = Math::Max(Settings.AttackProjectileSpeed, CurrentSpeed - SpeedDiff * Acceleration * DeltaTime);
			ProjectileComp.Velocity = ProjectileComp.Velocity.GetSafeNormal() * CurrentSpeed;
		}

		LocalMovement(DeltaTime);

		if (LaunchDuration > ExpirationTime)
		{
			Expire(FHitResult());
		}
	}

	bool ShouldStopHoming(FVector TargetLocation)
	{	
		if (bShouldStopHomingWhenPassed)
			return false;

		if (!HomingProjectileComp.bUseJetpackFriendlyHoming && ProjectileComp.Velocity.DotProduct(TargetLocation - ActorLocation) < 0)
		{
			return true;
		}
		else if (HomingProjectileComp.bUseJetpackFriendlyHoming &&
			(ActorForwardVector.DotProduct((TargetLocation - ActorLocation).GetSafeNormal()) < 0.83 ||
			Math::Abs(ActorForwardVector.DotProduct(FVector::UpVector)) > 0.98)) // about 11.5 degrees from straight upwards or downwards)
		{
			return true;
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
		FIslandShieldotronRocketProjectileOnImpactData Params;
		Params.HitResult = Hit;
		UIslandShieldotronRocketProjectileEffectHandler::Trigger_OnImpact(this, Params);
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
				HitPlayer.DamagePlayerHealth(Settings.RocketDamagePlayer, FPlayerDeathDamageParams(), nullptr, nullptr);
				
				FVector ImpactDir = (HitPlayer.ActorCenterLocation - ExplosionLocation).GetNormalized2DWithFallback(-HitPlayer.ActorForwardVector);
				if (ImpactDir.Size() < SMALL_NUMBER)
					ImpactDir = HitPlayer.ActorForwardVector * -1.0;
				HitPlayer.ApplyStumble(ImpactDir * 100.0, 0.5);
				
				FIslandShieldotronRocketProjectileOnPlayerImpactData Params;
				Params.Player = HitPlayer;
				Params.ImpactDirection = ImpactDir;
				// temp, prevent screen shake in sidescroller
				UPlayerMovementPerspectiveModeComponent PerspectiveComp = UPlayerMovementPerspectiveModeComponent::Get(HitPlayer);
				if (PerspectiveComp == nullptr || (PerspectiveComp != nullptr && PerspectiveComp.IsIn3DPerspective()))
					UIslandShieldotronRocketProjectileEffectHandler::Trigger_OnPlayerDamage(this, Params);
			}
		}
	}
}

class UIslandShieldotronHomingProjectileComponent : UBasicAIHomingProjectileComponent
{	
	bool bUseJetpackFriendlyHoming = false;
	FVector TargetGroundLocation = FVector::ZeroVector;
	FVector GetPlanarHomingAcceleration(FVector TargetLocation, FVector PlaneNormal, float HomingStrength) override
	{
		if (Target == nullptr && TargetLocation.IsZero())
			return FVector::ZeroVector;
		
		FVector ToTarget = (TargetLocation - Owner.ActorLocation);
		FVector	PerpendicularToTarget = ToTarget.VectorPlaneProject(PlaneNormal);
		return PerpendicularToTarget * HomingStrength;
	}
}
