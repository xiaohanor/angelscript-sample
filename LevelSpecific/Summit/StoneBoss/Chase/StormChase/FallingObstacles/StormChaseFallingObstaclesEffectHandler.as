struct FStormChaseFallingObstacleAcidParams
{
	UPROPERTY()
	FVector Location;
}

struct FStormChaseFallingObstacleCrystalSmashParams
{
	UPROPERTY()
	FVector Location;
}

UCLASS(Abstract)
class UStormChaseFallingObstaclesEffectHandler : UHazeEffectEventHandler
{
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnAcidImpact() {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnSmashImpact() {}
};