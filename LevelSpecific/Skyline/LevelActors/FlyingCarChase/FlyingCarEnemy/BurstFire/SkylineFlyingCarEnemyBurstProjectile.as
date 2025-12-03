
UCLASS(Abstract)
class ASkylineFlyingCarEnemyBurstProjectile : AHazeActor
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
	float ExpirationTime = 10.0;

	USkylineFlyingCarEnemyShipSettings Settings;

	void InitSettings()
	{
		Settings = USkylineFlyingCarEnemyShipSettings::GetSettings(ProjectileComp.Launcher);
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
			AActor Controller = ProjectileComp.Launcher;
			if (Hit.Actor != nullptr && (Hit.Actor.IsA(ASkylineFlyingCar) || Hit.Actor.IsA(AHazePlayerCharacter)) )
				Controller = Hit.Actor;
			if (Controller.HasControl())	
			{				
				if (IsObjectNetworked())
					CrumbImpact(Hit); 
				else
				{
					LocalImpact(Hit);
					//ProjectileComp.Impact(Hit); // TODO: replace basic ai projectile comp with sub class.
				}
			}
			else
			{
				// Visual impact and local damage (player car explodes on control only)
				LocalImpact(Hit);				
			}
		}

		if (Time::GetGameTimeSince(ProjectileComp.LaunchTime) > ExpirationTime)
			ProjectileComp.Expire();
	}

	UFUNCTION(CrumbFunction, NotBlueprintCallable)
	private void CrumbImpact(FHitResult Hit)
	{
		LocalImpact(Hit);
	}

	void LocalImpact(FHitResult Hit)
	{
		USkylineFlyingCarEnemyBurstFireProjectileEventHandler::Trigger_OnImpact(this, FSkylineFlyingCarEnemyBurstFireProjectileOnImpactEventData(Hit));
		//ProjectileComp.Impact(Hit);
		USkylineFlyingCarHealthComponent FCHealthComp = USkylineFlyingCarHealthComponent::Get(Hit.Actor);
		if (FCHealthComp != nullptr)
		{
			FSkylineFlyingCarDamage FCDamage;
			FCDamage.Amount = Settings.BurstProjectileDamage;
			FCHealthComp.TakeDamage(FCDamage);
		}
		ProjectileComp.Expire();
	}	
}

class USkylineFlyingCarEnemyBurstProjectileComponent :  UBasicAIProjectileComponent
{
	bool IsSignificantImpact(FHitResult Hit) override
	{
		if (Hit.Actor == nullptr)
			return false;
		UPlayerHealthComponent PlayerHealthComp = UPlayerHealthComponent::Get(Hit.Actor);
		if (PlayerHealthComp != nullptr)
			return true;
		return false;
	}

	void Impact(FHitResult Hit) override
	{
		FBasicAiProjectileOnImpactData Data;
		Data.HitResult = Hit;
		UBasicAIProjectileEffectHandler::Trigger_OnImpact(HazeOwner, Data);
		Expire();

		// Deal damage
		if (Hit.Actor == nullptr)
			return;

		USkylineFlyingCarHealthComponent FCHealthComp = USkylineFlyingCarHealthComponent::Get(Hit.Actor);
		if (FCHealthComp != nullptr)
		{
			FSkylineFlyingCarDamage FCDamage;
			FCDamage.Amount = Damage;
			FCHealthComp.TakeDamage(FCDamage);
		}
	}

}