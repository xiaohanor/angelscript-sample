
UCLASS(Abstract)
class ABasicAIProjectile : AHazeActor
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

	// After this time we automatically expire
	UPROPERTY()
	float ExpirationTime = 2.0;

	// Projectile will start ticking when launched and will be disabled when it expires
	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaTime)
	{
		if (!ProjectileComp.bIsLaunched)
			return;

		// Local movement, should be deterministic(ish)
		FHitResult Hit;
		SetActorLocation(ProjectileComp.GetUpdatedMovementLocation(DeltaTime, Hit));
		if (Hit.bBlockingHit)
		{
			AActor Controller = ProjectileComp.Launcher;
			if ((Hit.Actor != nullptr) && (Hit.Actor.IsA(AHazePlayerCharacter)))
				Controller = Hit.Actor;
			if (Controller.HasControl() && ProjectileComp.IsSignificantImpact(Hit))	
			{
				if (IsObjectNetworked())
					CrumbImpact(Hit); 
				else
					LauncherCrumbImpact(Hit);
			}
			else
			{
				// Visual impact only
				OnLocalImpact(Hit);
				ProjectileComp.Expire();
			}
		}

		if (Time::GetGameTimeSince(ProjectileComp.LaunchTime) > ExpirationTime)
			ProjectileComp.Expire();
	}

	UFUNCTION(CrumbFunction, NotBlueprintCallable)
	private void CrumbImpact(FHitResult Hit)
	{
		OnImpact(Hit);
		ProjectileComp.Impact(Hit);
	}

	private void LauncherCrumbImpact(FHitResult Hit)
	{
		// Network impacts through the projectile launcher component that launched this projectile
		// Note that this means a single projectile can potentially impact against two different target on each side in network.
		UBasicAIProjectileLauncherComponent LaunchingWeapon = Cast<UBasicAIProjectileLauncherComponent>(ProjectileComp.LaunchingWeapon);	
		LaunchingWeapon.CrumbProjectileImpact(Hit, ProjectileComp.Damage, ProjectileComp.DamageType, ProjectileComp.Launcher);
		OnLocalImpact(Hit);
		ProjectileComp.Expire();
	}

	// Impact
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnImpact(FHitResult Hit) {}

	// Projectile impacted on local side, any gameplay need to be networked if started here
	UFUNCTION(BlueprintEvent)
	void OnLocalImpact(FHitResult Hit) {}
}
