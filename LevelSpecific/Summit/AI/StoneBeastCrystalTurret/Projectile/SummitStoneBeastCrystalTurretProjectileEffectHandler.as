UCLASS(Abstract)
class USummitStoneBeastCrystalTurretProjectileEventHandler : UHazeEffectEventHandler
{	
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnLaunch() {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnImpact(FSummitStoneBeastCrystalTurretProjectileOnImpactEventData Data) {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnPlayerDamage(FSummitStoneBeastCrystalTurretProjectileOnPlayerDamageEventData Data) {}
}


struct FSummitStoneBeastCrystalTurretProjectileOnImpactEventData
{
	UPROPERTY(BlueprintReadOnly)
	FHitResult HitResult;

	FSummitStoneBeastCrystalTurretProjectileOnImpactEventData(FHitResult InHitResult)
	{
		HitResult = InHitResult;
	}
}

struct FSummitStoneBeastCrystalTurretProjectileOnPlayerDamageEventData
{
	UPROPERTY(BlueprintReadOnly)
	FVector ImpactLocation;

	UPROPERTY(BlueprintReadOnly)
	FVector ImpactDirection;
	
	UPROPERTY(BlueprintReadOnly)
	AHazePlayerCharacter HitPlayer;

	FSummitStoneBeastCrystalTurretProjectileOnPlayerDamageEventData(FVector InImpactLocation, FVector InImpactDirection, AHazePlayerCharacter InHitPlayer)
	{
		ImpactLocation = InImpactLocation;
		ImpactDirection = InImpactDirection;
		HitPlayer = InHitPlayer;
	}
}

