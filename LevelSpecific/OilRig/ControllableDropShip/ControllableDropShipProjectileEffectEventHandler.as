struct FControllableDropShipProjectileImpactParams
{
	UPROPERTY()
	FVector ImpactLocation;

	UPROPERTY()
	UPhysicalMaterialAudioAsset AudioPhysMat;
}

UCLASS(Abstract)
class UControllableDropShipProjectileEffectEventHandler : UHazeEffectEventHandler
{
	UFUNCTION(BlueprintEvent)
	void ShotImpact(FControllableDropShipProjectileImpactParams Params) {}
}