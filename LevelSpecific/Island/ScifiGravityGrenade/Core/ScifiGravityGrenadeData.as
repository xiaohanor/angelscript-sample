class UScifiPlayerGravityGrenadeSettings : UHazeComposableSettings
{
	// The speed we start with when we launch the projectile
	UPROPERTY(Category = "Projectile|Movement")
	float Speed = 2000;

	// How long we have to hold to activate the projectile
	UPROPERTY(Category = "Projectile|Shoot")
	float ActivationTime = 1.0;

	// How long the projectile lives
	UPROPERTY(Category = "Projectile|Shoot")
	float ProjectileMaxLifeTime = 10.0;

	// The initial velocity of the visual mesh, which makes it move in an arc
	UPROPERTY(Category = "Projectile|Movement")
	float InitialUpVelocityNoTarget = 400.0;

	// Gravity on the visual mesh
	UPROPERTY(Category = "Projectile|Movement")
	float Gravity = 2000.0;
}

struct FScifiPlayerGravityGrenadeWeaponImpact
{
	bool bIsValid = false;
	FVector ImpactLocation;
	AActor Actor;
	UScifiGravityGrenadeTargetableComponent Target;

	FScifiPlayerGravityGrenadeWeaponImpact()
	{

	}

	FScifiPlayerGravityGrenadeWeaponImpact(FHitResult FromHitResult, UScifiGravityGrenadeTargetableComponent CustomTarget = nullptr)
	{
		if(FromHitResult.bBlockingHit && FromHitResult.Actor != nullptr)
		{
			bIsValid = true;
			ImpactLocation = FromHitResult.ImpactPoint;
			Actor = FromHitResult.Actor;
			if(CustomTarget != nullptr)
				Target = CustomTarget;
			else
				Target = UScifiGravityGrenadeTargetableComponent::Get(Actor);
		}
	}
}