
class AIslandTurretProjectile : AHazeActor
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
	default ProjectileComp.bIgnoreDescendants = false;

	UPROPERTY(DefaultComponent)
	UHazeActorRespawnableComponent RespawnComp;

	UPROPERTY(DefaultComponent)
	UCapsuleComponent HitCollision;

	UPROPERTY(DefaultComponent, Attach = "HitCollision")
	UIslandNunchuckImpactResponseComponent NunchuckResponseComp;

	UPROPERTY(DefaultComponent)
	UIslandNunchuckTargetableComponent NunchuckTargetableComp;
	default NunchuckTargetableComp.bCanTraversToTarget = false;

	// After this time we automatically expire
	UPROPERTY()
	float ExpirationTime = 3.0;

	bool bDeflected;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		NunchuckResponseComp.OnMeleeImpactEvent.AddUFunction(this, n"OnNunchuckHit");
		RespawnComp.OnRespawn.AddUFunction(this, n"OnReset");
	}



	UFUNCTION()
	private void OnReset()
	{
		ProjectileComp.TraceType = ETraceTypeQuery::WeaponTraceEnemy;
		bDeflected = false;
	}

	UFUNCTION()
	private void OnNunchuckHit(AHazePlayerCharacter ImpactInstigator,
	                           UIslandNunchuckImpactResponseComponent Component)
	{
		if(!bDeflected)
			bDeflected = true;

		auto TurretSettings = UIslandTurretSettings::GetSettings(ProjectileComp.Launcher);

		// Do this before changing the launcher
		FVector Dir = (ProjectileComp.Launcher.ActorCenterLocation - ActorLocation).GetSafeNormal();

		AHazeActor Launcher = Cast<AHazeActor>(ImpactInstigator);
		ProjectileComp.TraceType = ((Launcher == Game::Zoe) ? ETraceTypeQuery::WeaponTraceZoe : ETraceTypeQuery::WeaponTraceMio);
		ProjectileComp.Launcher = Launcher;
		ProjectileComp.bIsLaunched = false;
		ProjectileComp.Launch(Dir * ProjectileComp.Velocity.Size() * TurretSettings.DeflectSpeedMultiplier);
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
			Impact(Hit);
		}

		if (Time::GetGameTimeSince(ProjectileComp.LaunchTime) > ExpirationTime)
			ProjectileComp.Expire();
	}

	void Impact(FHitResult Hit)
	{
		FBasicAiProjectileOnImpactData Data;
		Data.HitResult = Hit;
		UBasicAIProjectileEffectHandler::Trigger_OnImpact(this, Data);
		ProjectileComp.Expire();

		if (Hit.Actor != nullptr)
		{
			auto TurretSettings = UIslandTurretSettings::GetSettings(ProjectileComp.Launcher);
			UPlayerHealthComponent PlayerHealthComp = UPlayerHealthComponent::Get(Hit.Actor);
			if (PlayerHealthComp != nullptr)
				PlayerHealthComp.DamagePlayer(TurretSettings.ProjectileDamagePlayer, nullptr, nullptr);
			UBasicAIHealthComponent NPCHealthComp = UBasicAIHealthComponent::Get(Hit.Actor);
			if (NPCHealthComp != nullptr)
			{
				auto Shield = UScifiShieldBusterField::Get(Hit.Actor);
				if(Shield == nullptr || !Shield.IsEnabled() || Shield.IsBroken())
				{
					NPCHealthComp.TakeDamage(TurretSettings.ProjectileDamageNpc, ProjectileComp.DamageType, ProjectileComp.Launcher);
				}				
			}
		}
	}

	// Impact
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnImpact(FHitResult Hit) {}
}
