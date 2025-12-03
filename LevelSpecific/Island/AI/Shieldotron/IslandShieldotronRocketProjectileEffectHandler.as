struct FIslandShieldotronRocketProjectileOnLaunchData
{
	UPROPERTY()
	FVector MuzzleLocation;
}
	

struct FIslandShieldotronRocketProjectileOnImpactData
{
	UPROPERTY()
	FHitResult HitResult;
}

struct FIslandShieldotronRocketProjectileOnPlayerImpactData
{
	UPROPERTY()
	FVector ImpactDirection;

	UPROPERTY()
	AHazePlayerCharacter Player; 
}

UCLASS(Abstract)
class UIslandShieldotronRocketProjectileEffectHandler : UHazeEffectEventHandler
{
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
    void OnLaunch(FIslandShieldotronRocketProjectileOnLaunchData Params) {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
    void OnImpact(FIslandShieldotronRocketProjectileOnImpactData Params) {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
    void OnPlayerDamage(FIslandShieldotronRocketProjectileOnPlayerImpactData Params) {}
}

