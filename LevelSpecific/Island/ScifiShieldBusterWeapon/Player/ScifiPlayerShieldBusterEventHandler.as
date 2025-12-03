struct FScifiPlayerShieldBusterOnShootEventData
{
	UPROPERTY(BlueprintReadOnly)
	AScifiPlayerShieldBusterWeaponProjectile Projectile;

	UPROPERTY(BlueprintReadOnly)
	FVector HandLocation;

	UPROPERTY(BlueprintReadOnly)
	FVector ShootDirection;
}

struct FScifiPlayerShieldBusterDeactivatedEventData
{
	UPROPERTY(BlueprintReadOnly)
	AScifiPlayerShieldBusterWeaponProjectile Projectile;
}

struct FScifiPlayerShieldBusterOnImpactEventData
{
	UPROPERTY(BlueprintReadOnly)
	FVector ImpactLocation;

	UPROPERTY(BlueprintReadOnly)
	UScifiShieldBusterTargetableComponent ImpactTarget;
}



UCLASS(Abstract, Meta = (RequireActorType = "AHazePlayerCharacter"))
class UScifiPlayerShieldBusterEventHandler : UHazeEffectEventHandler
{

	AHazePlayerCharacter Player = nullptr;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Player = Cast<AHazePlayerCharacter>(Owner);
	}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnShoot(FScifiPlayerShieldBusterOnShootEventData OnShootData) 
	{ 
	
	}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnImpact(FScifiPlayerShieldBusterOnImpactEventData OnImpactData)
	{

	}

	/** Happens when it collides or returns to the hand or impacts with the wall */
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnProjectileDeactivated(FScifiPlayerShieldBusterDeactivatedEventData OnDeactivationData)
	{

	}
}