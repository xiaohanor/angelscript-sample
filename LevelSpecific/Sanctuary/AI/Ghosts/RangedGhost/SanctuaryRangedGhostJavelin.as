
class ASanctuaryRangedGhostJavelin : AHazeActor
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

	FHazeAcceleratedVector AccDir;

	// After this time we automatically expire
	UPROPERTY()
	float ExpirationTime = 2.0;

	int Index;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		ProjectileComp.OnLaunch.AddUFunction(this, n"OnLaunch");
		RespawnComp.OnUnspawn.AddUFunction(this, n"OnUnspawn");
	}

	UFUNCTION()
	private void OnUnspawn(AHazeActor RespawnableActor)
	{
		USanctuaryRangedGhostEventHandler::Trigger_OnRemoveTargetIndicator(ProjectileComp.Launcher, FSanctuaryRangedGhostRemoveTargetIndicatorParameters(Index));
	}

	UFUNCTION()
	private void OnLaunch(UBasicAIProjectileComponent Projectile)
	{
		AccDir.SnapTo(ActorForwardVector);
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
			OnImpact(Hit);
			ProjectileComp.Impact(Hit);
		}

		SetActorRotation(AccDir.AccelerateTo(ProjectileComp.Velocity.GetSafeNormal(), 0.5, DeltaTime).Rotation());

		if (Time::GetGameTimeSince(ProjectileComp.LaunchTime) > ExpirationTime)
		{
			ProjectileComp.Expire();
		}
	}

	// Impact
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnImpact(FHitResult Hit) {}
}