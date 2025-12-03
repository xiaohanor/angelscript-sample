UCLASS(Abstract)
class AIslandOverseerMissileProjectile : AHazeActor
{
	default PrimaryActorTick.bStartWithTickEnabled = false;

	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent)
	UHazeSkeletalMeshComponentBase Mesh;
	default Mesh.CollisionProfileName = n"NoCollision";
	default Mesh.bCanEverAffectNavigation = false;

	UPROPERTY(DefaultComponent)
	UBasicAIProjectileComponent ProjectileComp;
	default ProjectileComp.Friction = 0.01;
	default ProjectileComp.Gravity = 9.82;

	UPROPERTY(DefaultComponent)
	UHazeActorRespawnableComponent RespawnComp;

	UPROPERTY()
	TSubclassOf<UDamageEffect> DamageEffect;

	UPROPERTY()
	TSubclassOf<UDeathEffect> DeathEffect;

	// After this time we automatically expire
	UPROPERTY()
	float ExpirationTime = 15.0;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		ProjectileComp.OnLaunch.AddUFunction(this, n"OnLaunch");
	}

		UFUNCTION()
	private void OnUnspawn(AHazeActor RespawnableActor)
	{
		UIslandOverseerMissileProjectileEventHandler::Trigger_OnExpire(this);
	}

	UFUNCTION()
	private void OnReset()
	{
		UIslandOverseerMissileProjectileEventHandler::Trigger_OnExpire(this);
	}

	UFUNCTION()
	private void OnLaunch(UBasicAIProjectileComponent Projectile)
	{
		UIslandOverseerMissileProjectileEventHandler::Trigger_OnLaunch(this, FIslandOverseerMissileProjectileOnLaunchEventData(Projectile.Owner.ActorLocation));
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
		SetActorRotation(ProjectileComp.Velocity.Rotation());

		if (Hit.bBlockingHit)
		{
			AActor Controller = ProjectileComp.Launcher;
			if ((Hit.Actor != nullptr) && (Hit.Actor.IsA(AHazePlayerCharacter)))
				Controller = Hit.Actor;
			if (Controller.HasControl())	
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
				UIslandOverseerMissileProjectileEventHandler::Trigger_OnHit(this, FIslandOverseerMissileProjectileOnHitEventData(Hit));
			}
		}

		if (Time::GetGameTimeSince(ProjectileComp.LaunchTime) > ExpirationTime)
			ProjectileComp.Expire();
	}

	UFUNCTION(CrumbFunction, NotBlueprintCallable)
	private void CrumbImpact(FHitResult Hit)
	{
		OnImpact(Hit);
		Impact(Hit);
		UIslandOverseerMissileProjectileEventHandler::Trigger_OnHit(this, FIslandOverseerMissileProjectileOnHitEventData(Hit));
	}

	void Impact(FHitResult Hit)
	{
		FBasicAiProjectileOnImpactData Data;
		Data.HitResult = Hit;
		UBasicAIProjectileEffectHandler::Trigger_OnImpact(ProjectileComp.HazeOwner, Data);
		ProjectileComp.Expire();

		for(AHazePlayerCharacter Player : Game::Players)
		{
			if(Player.GetDistanceTo(this) < 150)
				RangeHit(Player);
		}		
	}

	void RangeHit(AHazePlayerCharacter Player)
	{
		UPlayerHealthComponent PlayerHealthComp = UPlayerHealthComponent::Get(Player);
		if (PlayerHealthComp != nullptr)
			PlayerHealthComp.DamagePlayer(ProjectileComp.Damage, DamageEffect, DeathEffect);

		FStumble Stumble;
		FVector Dir = ProjectileComp.Launcher.ActorForwardVector + FVector(0, 0, 0.2);
		Stumble.Move = Dir * 500;
		Stumble.Duration = 0.25;
		Player.ApplyStumble(Stumble);
	}

	private void LauncherCrumbImpact(FHitResult Hit)
	{
		// Network impacts through the projectile launcher component that launched this projectile
		// Note that this means a single projectile can potentially impact against two different target on each side in network.
		UBasicAIProjectileLauncherComponent LaunchingWeapon = Cast<UBasicAIProjectileLauncherComponent>(ProjectileComp.LaunchingWeapon);	
		LaunchingWeapon.CrumbProjectileImpact(Hit, ProjectileComp.Damage, ProjectileComp.DamageType, ProjectileComp.Launcher);
		OnLocalImpact(Hit);
		ProjectileComp.Expire();
		UIslandOverseerMissileProjectileEventHandler::Trigger_OnHit(this, FIslandOverseerMissileProjectileOnHitEventData(Hit));
	}

	// Impact
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnImpact(FHitResult Hit) {}

	// Projectile impacted on local side, any gameplay need to be networked if started here
	UFUNCTION(BlueprintEvent)
	void OnLocalImpact(FHitResult Hit) {}
}