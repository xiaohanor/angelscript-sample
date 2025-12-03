struct FOnCrystalSiegerMortarImpactParams
{
	UPROPERTY()
	FVector ImpactLocation;

	UPROPERTY()
	FRotator ImpactRotation;
}

UCLASS(Abstract)
class UCrystalSiegerMortarEffectHandler : UHazeEffectEventHandler
{
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void MortarImpact(FOnCrystalSiegerMortarImpactParams Params) {}
};