
UCLASS(Abstract)
class AIslandShieldotronProjectile : AHazeActor
{
	default PrimaryActorTick.bStartWithTickEnabled = false;

	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent)
	UStaticMeshComponent Mesh;
	default Mesh.CollisionProfileName = n"NoCollision";
	default Mesh.bCanEverAffectNavigation = false;

	UPROPERTY(DefaultComponent)
	UIslandProjectileComponent ProjectileComp;
	default ProjectileComp.Friction = 0.01;
	default ProjectileComp.Gravity = 9.82;

	UPROPERTY(DefaultComponent)
	UHazeActorRespawnableComponent RespawnComp;

	// After this time we automatically expire
	UPROPERTY()
	float ExpirationTime = 4.0;

	bool bIsRotating;

	// Projectile will start ticking when launched and will be disabled when it expires
	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaTime)
	{
		if (!ProjectileComp.bIsLaunched)
			return;

		// Local movement, should be deterministic(ish)
		FHitResult Hit;
		SetActorLocation(ProjectileComp.GetUpdatedMovementLocation(DeltaTime, Hit));
		if (bIsRotating)
			AddActorLocalRotation(FRotator(2000*DeltaTime, 0, 0));
		if (Hit.bBlockingHit && !IslandForceField::HasHitForceFieldObstacleHole(Hit))
		{
			if ((Hit.Actor != nullptr) && (Hit.Actor.IsA(AHazePlayerCharacter)))
			{
				if (Hit.Actor.HasControl() && ProjectileComp.IsSignificantImpact(Hit))		
					LauncherCrumbImpact(Hit);
				else
					LocalImpact(Hit);
			}
			else
				LocalImpact(Hit);
		}

		if (Time::GetGameTimeSince(ProjectileComp.LaunchTime) > ExpirationTime)
			ProjectileComp.Expire();
	}

	private void LauncherCrumbImpact(FHitResult Hit)
	{
		LocalImpact(Hit);
		
		// Network impacts through the projectile launcher component that launched this projectile
		// Note that this means a single projectile can potentially impact against two different target on each side in network.
		UBasicAIProjectileLauncherComponent LaunchingWeapon = Cast<UBasicAIProjectileLauncherComponent>(ProjectileComp.LaunchingWeapon);
		LaunchingWeapon.CrumbProjectileImpactTypedDamage(Hit, ProjectileComp.Damage, ProjectileComp.Launcher, EDamageEffectType::ProjectilesSmall, EDeathEffectType::ProjectilesSmall);
	}

	// Visual impact only
	private void LocalImpact(FHitResult Hit)
	{
		FBasicAiProjectileOnImpactData Data;
		Data.HitResult = Hit;
		UBasicAIProjectileEffectHandler::Trigger_OnImpact(this, Data);
		ProjectileComp.Expire();
	}
		
}
