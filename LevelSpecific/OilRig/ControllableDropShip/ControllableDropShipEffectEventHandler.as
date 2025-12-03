UCLASS(Abstract)
class UControllableDropShipEffectEventHandler : UHazeEffectEventHandler
{
	UFUNCTION(BlueprintEvent)
	void ShotFired(FControllabeDropShipShootParams Params) {}

	UFUNCTION(BlueprintEvent)
	void ShotImpact(FControllableDropShipShotImpactParams Params) {}
}

struct FControllabeDropShipShootParams
{
	UPROPERTY()
	USceneComponent MuzzleComp;

	UPROPERTY()
	FVector EndLocation;
}

struct FControllableDropShipShotImpactParams
{
	UPROPERTY()
	FVector ImpactLocation;

	UPROPERTY()
	FVector ImpactNormal;
}