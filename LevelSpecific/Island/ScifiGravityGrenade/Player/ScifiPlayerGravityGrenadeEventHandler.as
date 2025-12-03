struct FScifiPlayerGravityGrenadeOnShootEventData
{
	UPROPERTY(BlueprintReadOnly)
	AScifiPlayerGravityGrenadeWeaponProjectile Projectile;

	UPROPERTY(BlueprintReadOnly)
	FVector HandLocation;

	UPROPERTY(BlueprintReadOnly)
	FVector ShootDirection;
}

struct FScifiPlayerGravityGrenadeDeactivatedEventData
{
	UPROPERTY(BlueprintReadOnly)
	AScifiPlayerGravityGrenadeWeaponProjectile Projectile;
}

struct FScifiPlayerGravityGrenadeOnImpactEventData
{
	UPROPERTY(BlueprintReadOnly)
	FVector ImpactLocation;

	UPROPERTY(BlueprintReadOnly)
	UScifiGravityGrenadeTargetableComponent ImpactTarget;
}



UCLASS(Abstract)
class UScifiPlayerGravityGrenadeEventHandler : UHazeEffectEventHandler
{

	AHazePlayerCharacter Player = nullptr;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Player = Cast<AHazePlayerCharacter>(Owner);
	}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnShoot(FScifiPlayerGravityGrenadeOnShootEventData OnShootData) 
	{ 
	
	}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnImpact(FScifiPlayerGravityGrenadeOnImpactEventData OnImpactData)
	{

	}

	/** Happens when it collides or returns to the hand or impacts with the wall */
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnProjectileDeactivated(FScifiPlayerGravityGrenadeDeactivatedEventData OnDeactivationData)
	{

	}
}