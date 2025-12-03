UCLASS(Abstract)
class ASanctuaryGrimbeastMortarProjectile : AHazeActor
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
	USanctuaryLavaApplierComponent LavaComp;

	UPROPERTY(DefaultComponent)
	UHazeActorRespawnableComponent RespawnComp;

	// After this time we automatically expire
	UPROPERTY()
	float ExpirationTime = 10.0;

	UPROPERTY()
	TSubclassOf<ASanctuaryGrimbeastMortarPool> MortalPoolClass;

	AHazeActor Owner;
	FVector AttackLocation;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		ProjectileComp.OnLaunch.AddUFunction(this, n"OnLaunch");
	}

	UFUNCTION()
	private void OnLaunch(UBasicAIProjectileComponent Projectile)
	{
		USanctuaryGrimbeastMortarProjectileEventHandler::Trigger_OnLaunch(this, FSanctuaryGrimbeastMortarProjectileOnLaunchEventData(AttackLocation));
	}

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
			if (Cast<AHazePlayerCharacter>(Hit.Actor) != nullptr || 
				Cast<ACentipede>(Hit.Actor) != nullptr)
				LavaComp.SingleApplyLavaHitOnWholeCentipede();
			ProjectileComp.Expire();
			SpawnPool();
			USanctuaryGrimbeastMortarProjectileEventHandler::Trigger_OnHit(this);
		}

		if (Time::GetGameTimeSince(ProjectileComp.LaunchTime) > ExpirationTime)
			ProjectileComp.Expire();
	}

	private void SpawnPool()
	{
		ASanctuaryGrimbeastMortarPool Pool = SpawnActor(MortalPoolClass, ActorLocation, bDeferredSpawn = true);
		Pool.Owner = Owner;
		FinishSpawningActor(Pool);
	}
}