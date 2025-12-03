UCLASS(Abstract)
class ASanctuaryLavamoleBoulderProjectile : AHazeActor
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

	UPROPERTY(DefaultComponent)
	USanctuaryLavaApplierComponent LavaComp;

	// After this time we automatically expire
	UPROPERTY()
	float ExpirationTime = 15.0;

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
		USanctuaryLavamoleBoulderProjectileEventHandler::Trigger_OnLaunch(this, FSanctuaryLavamoleBoulderProjectileOnLaunchEventData(AttackLocation));
	}

	// Projectile will start ticking when launched and will be disabled when it expires
	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaTime)
	{
		if (!ProjectileComp.bIsLaunched)
			return;

		FHitResult Hit;
		SetActorLocation(ProjectileComp.GetUpdatedMovementLocation(DeltaTime, Hit));
		SetActorRotation(ProjectileComp.Velocity.GetSafeNormal2D().Rotation());

		LavaComp.ManualEndOverlapWholeCentipedeApply();
		bool bHit = false;
		for(FVector Location: GetBodyLocations())
		{
			if(!ActorLocation.IsWithinDist(Location, 90))
				continue;
			LavaComp.OverlapSingleFrame(Location, 90, false);
			bHit = true;
		}

		if (bHit)
		{
			ProjectileComp.Expire();
			USanctuaryLavamoleBoulderProjectileEventHandler::Trigger_OnHit(this, FSanctuaryLavamoleBoulderProjectileOnHitEventData(Hit));
		}

		if (Time::GetGameTimeSince(ProjectileComp.LaunchTime) > ExpirationTime)
			ProjectileComp.Expire();

		float Rotation = -ProjectileComp.Velocity.Size() * DeltaTime * 0.5;
		Mesh.AddLocalRotation(FRotator(Rotation, 0, 0));
	}

	private TArray<FVector> GetBodyLocations() const
	{
		TArray<FVector> Locations;
		UPlayerCentipedeComponent CentipedeComp = UPlayerCentipedeComponent::Get(Game::Mio);
		if(ensure(CentipedeComp != nullptr, "Can only target centipede players!"))
			Locations = CentipedeComp.GetBodyLocations();
		return Locations;
	}
}