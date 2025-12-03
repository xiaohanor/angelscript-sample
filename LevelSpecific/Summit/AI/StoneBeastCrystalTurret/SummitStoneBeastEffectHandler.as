struct FSummitStoneBeastCrystalTurretDamageParams
{
	FSummitStoneBeastCrystalTurretDamageParams(FVector Location)
	{
		HitLocation = Location;
	}

	UPROPERTY()
	FVector HitLocation;
}


struct FSummitStoneBeastCrystalTurretTelegraphingParams
{
	FSummitStoneBeastCrystalTurretTelegraphingParams(FVector InMuzzleLocation, FVector TurretLocation)
	{
		MuzzleLocation = InMuzzleLocation;
		TurretActorLocation = TurretLocation;
	}

	UPROPERTY()
	FVector MuzzleLocation;
	
	UPROPERTY()
	FVector TurretActorLocation;
}

UCLASS(Abstract)
class USummitStoneBeastCrystalTurretEffectHandler : UHazeEffectEventHandler
{
    UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
    void OnDeath() {}

    UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
    void OnDamage(FSummitStoneBeastCrystalTurretDamageParams Params) {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
    void OnStartTelegraphing(FSummitStoneBeastCrystalTurretTelegraphingParams Params) {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
    void OnStopTelegraphing() {}
}