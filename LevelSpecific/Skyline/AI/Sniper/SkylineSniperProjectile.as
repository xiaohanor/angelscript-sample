
struct FSkylineSniperProjectileImpactParams
{
	UPROPERTY()
	FHitResult Hit;
}

class USkylineSniperProjectileEventHandler : UHazeEffectEventHandler
{
	UFUNCTION(BlueprintEvent)
	void OnImpact(FSkylineSniperProjectileImpactParams Params) {};
}

class ASkylineSniperProjectile : AHazeActor
{
	default PrimaryActorTick.bStartWithTickEnabled = false;

	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent)
	UStaticMeshComponent Mesh;
	default Mesh.CollisionProfileName = n"NoCollision";
	default Mesh.bCanEverAffectNavigation = false;

	UPROPERTY(DefaultComponent)
	USkylineSniperProjectileComponent ProjectileComp;
	default ProjectileComp.Friction = 0.01;
	default ProjectileComp.Gravity = 9.82;

	UPROPERTY(DefaultComponent)
	UHazeActorRespawnableComponent RespawnComp;

	// After this time we automatically expire
	UPROPERTY()
	float ExpirationTime = 4.0;

	bool Expired = false;

	// Projectile will start ticking when launched and will be disabled when it expires
	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaTime)
	{
		if(ProjectileComp.ExpiredTime != 0)
		{
			USkylineSniperSettings Settings = USkylineSniperSettings::GetSettings(ProjectileComp.Launcher);
			if(Time::GetGameTimeSince(ProjectileComp.ExpiredTime) > Settings.ProjectileHitLinger)
			{
				ProjectileComp.DelayedExpire();
			}
			return;
		}

		if (!ProjectileComp.bIsLaunched)
			return;

		// Local movement, should be deterministic(ish)
		FHitResult Hit;
		SetActorLocation(ProjectileComp.GetUpdatedMovementLocation(DeltaTime, Hit));
		if (Hit.bBlockingHit)
		{
			OnImpact(Hit);
			ProjectileComp.Impact(Hit);

			FSkylineSniperProjectileImpactParams ImpactParams;
			ImpactParams.Hit = Hit;

			USkylineSniperProjectileEventHandler::Trigger_OnImpact(ProjectileComp.GetLauncher(), ImpactParams);
		}

		if (Time::GetGameTimeSince(ProjectileComp.LaunchTime) > ExpirationTime)
			ProjectileComp.Expire();
	}

	// Impact
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnImpact(FHitResult Hit) {}
}