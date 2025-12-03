
enum EScifiPlayerShieldBusterHand
{
	Left,
	Right,
	MAX
}

class UScifiPlayerShieldBusterSettings : UHazeComposableSettings
{
	// The speed we start with when we launch the projectile
	UPROPERTY(Category = "Projectile|Movement")
	float InitialSpeed = 2000;

	// How much the projectile accelerates
	UPROPERTY(Category = "Projectile|Movement")
	float SpeedAcceleration = 800;

	// The max speed the projectile can reach
	UPROPERTY(Category = "Projectile|Movement")
	float SpeedMax = 3000;


	// Can we throw using left hand
	UPROPERTY(Category = "Weapon|Shoot")
	bool bUseLeftHand = true;

	// Can we throw using right hand
	UPROPERTY(Category = "Weapon|Shoot")
	bool bUseRightHand = true;

	// How long time after a valid shot is the projetile released from the hand
	UPROPERTY(Category = "Weapon|Shoot")
	float ReleaseProjectileDelay = 0.01;


	// How many projectiles we can shoot before we need to reload. Only used if >= 0
	UPROPERTY(Category = "Weapon|Shoot")
	int MagCapacity = -1;

	// How long between each projectile until we can shoot again
	UPROPERTY(Category = "Weapon|Shoot")
	float CooldownBetweenProjectile = 0.3;

	// How long time until we can shoot again
	UPROPERTY(Category = "Weapon|Shoot")
	float ReloadTime = 1.0;

	// How many projectiles we can have active in the world at the same time. Only used if >= 0
	UPROPERTY(Category = "Weapon|Shoot")
	int MaxActiveProjectiles = -1;
	
	// If we haven't shot anything for this amount of time, the magasine is instantly reloaded. Only used if >= 0
	UPROPERTY(Category = "Weapon|Shoot")
	float InactiveAutomaticReload = -1;

	// How long the projectiles life before they are destroyed if not hitting anything.
	UPROPERTY(Category = "Weapon|Shoot")
	float ProjectileMaxLifeTime = 5.0;
}


struct FScifiPlayerShieldBusterWeaponImpact
{
	bool bIsValid = false;
	FVector ImpactLocation;
	AActor Actor;
	UScifiShieldBusterTargetableComponent Target;

	FScifiPlayerShieldBusterWeaponImpact()
	{

	}

	FScifiPlayerShieldBusterWeaponImpact(FHitResult FromHitResult, UScifiShieldBusterTargetableComponent CustomTarget = nullptr)
	{
		if(FromHitResult.bBlockingHit && FromHitResult.Actor != nullptr)
		{
			bIsValid = true;
			ImpactLocation = FromHitResult.ImpactPoint;
			Actor = FromHitResult.Actor;
			if(CustomTarget != nullptr)
				Target = CustomTarget;
			else
				Target = UScifiShieldBusterTargetableComponent::Get(Actor);
		}
	}
}