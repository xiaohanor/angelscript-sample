UCLASS(Abstract)
class ASkylineHighwayBossVehicleGunProjectile : AHazeActor
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
	default ProjectileComp.Friction = 0.00;

	UPROPERTY(DefaultComponent)
	UHazeActorRespawnableComponent RespawnComp;

	// After this time we automatically expire
	UPROPERTY()
	float ExpirationTime = 3.0;
	
	bool CheckHeight;
	FVector LaunchLocation;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		RespawnComp.OnRespawn.AddUFunction(this, n"OnReset");
		RespawnComp.OnUnspawn.AddUFunction(this, n"OnUnspawn");
	}

	UFUNCTION()
	private void OnUnspawn(AHazeActor RespawnableActor)
	{
		CheckHeight = false;
		USkylineHighwayBossVehicleGunProjectileEffectHandler::Trigger_OnExpire(this);
	}

	UFUNCTION()
	private void OnReset()
	{
		ProjectileComp.TraceType = ETraceTypeQuery::WeaponTraceEnemy;
		USkylineHighwayBossVehicleGunProjectileEffectHandler::Trigger_OnExpire(this);
	}

	// Projectile will start ticking when launched and will be disabled when it expires
	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaTime)
	{
		if (!ProjectileComp.bIsLaunched)
			return;

		// Local movement, should be deterministic(ish)
		FHitResult Hit;
		SetActorLocation(ProjectileComp.GetUpdatedMovementLocation(DeltaTime, Hit, false));
		
		if (CanImpact(Hit))
		{
			OnImpact(Hit);
			Impact(Hit);
		}

		if (Time::GetGameTimeSince(ProjectileComp.LaunchTime) > ExpirationTime)
		{
			ProjectileComp.Expire();
		}

		SetActorRotation(ProjectileComp.Velocity.Rotation());
	}

	bool CanImpact(FHitResult Hit)
	{
		if(!Hit.bBlockingHit)
			return false;
		if(CheckHeight && LaunchLocation.Z < ActorLocation.Z)
			return false;
		return true;
	}

	void Impact(FHitResult Hit)
	{
		FBasicAiProjectileOnImpactData Data;
		Data.HitResult = Hit;
		USkylineHighwayBossVehicleGunProjectileEffectHandler::Trigger_OnImpact(this, FSkylineHighwayBossVehicleGunProjectileEffectHandlerOnImpactData(Hit));
		ProjectileComp.Expire();

		auto TurretSettings = USkylineTurretSettings::GetSettings(ProjectileComp.Launcher);

		if (Hit.Actor != nullptr)
		{
			UPlayerHealthComponent PlayerHealthComp = UPlayerHealthComponent::Get(Hit.Actor);
			if (PlayerHealthComp != nullptr)
				PlayerHealthComp.DamagePlayer(0.5, nullptr, nullptr);
		}

		for(AHazePlayerCharacter Player : Game::Players)
		{
			if(Hit.Actor == Player)
				continue;

			if(Player.GetDistanceTo(this) < 100)
				Player.DamagePlayerHealth(0.5);
		}
	}

	// Impact
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnImpact(FHitResult Hit) {}
}