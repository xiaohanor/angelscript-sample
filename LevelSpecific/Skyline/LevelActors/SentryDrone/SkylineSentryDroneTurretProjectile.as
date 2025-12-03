
class ASkylineSentryDroneTurretProjectile : AHazeActor
{
	default PrimaryActorTick.bStartWithTickEnabled = false;

	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent)
	UStaticMeshComponent Mesh;
	default Mesh.CollisionProfileName = n"NoCollision";
	default Mesh.bCanEverAffectNavigation = false;

	UPROPERTY(DefaultComponent)
	UBasicAIProjectileComponent ProjectileComponent;
	default ProjectileComponent.Friction = 0.0;
	default ProjectileComponent.Gravity = 0.0;

	UPROPERTY(DefaultComponent)
	UHazeActorRespawnableComponent RespawnComp;

	// After this time we automatically expire
	UPROPERTY()
	float ExpirationTime = 3.0;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
	}

	// Projectile will start ticking when launched and will be disabled when it expires
	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaTime)
	{
		if (!ProjectileComponent.bIsLaunched)
			return;

		// Local movement, should be deterministic(ish)
		FHitResult HitResult;
		SetActorLocation(ProjectileComponent.GetUpdatedMovementLocation(DeltaTime, HitResult));
		if (HitResult.bBlockingHit)
		{
			OnImpact(HitResult);
			ProjectileComponent.Impact(HitResult);
		}

		if (Time::GetGameTimeSince(ProjectileComponent.LaunchTime) > ExpirationTime)
			ProjectileComponent.Expire();
	}

	// Impact
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnImpact(FHitResult HitResult) {}
}