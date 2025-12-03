struct FIslandShieldotronOrbProjectileOnPrimeData
{
	UPROPERTY()
	FVector MuzzleLocation;
	
	UPROPERTY()
	float PrimeTime;

	// Scale time	
	UPROPERTY()
	float LifeTime;
}
	

struct FIslandShieldotronOrbProjectileOnLaunchData
{
	UPROPERTY()
	FVector MuzzleLocation;
	
	UPROPERTY()
	float LaunchTime;

	// Max lifetime before expiring mid-air.	
	UPROPERTY()
	float LifeTime;
}
	

struct FIslandShieldotronOrbProjectileOnImpactData
{
	UPROPERTY()
	FHitResult HitResult;
}

struct FIslandShieldotronOrbProjectileOnPlayerImpactData
{
	UPROPERTY()
	FVector ImpactDirection;

	UPROPERTY()
	AHazePlayerCharacter Player; 
}

UCLASS(Abstract)
class UIslandShieldotronOrbProjectileEffectHandler : UHazeEffectEventHandler
{
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
    void OnPrime(FIslandShieldotronOrbProjectileOnPrimeData Params) {}
	
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
    void OnLaunch(FIslandShieldotronOrbProjectileOnLaunchData Params) {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
    void OnImpact(FIslandShieldotronOrbProjectileOnImpactData Params) {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
    void OnPlayerImpact(FIslandShieldotronOrbProjectileOnPlayerImpactData Params) {}
}

