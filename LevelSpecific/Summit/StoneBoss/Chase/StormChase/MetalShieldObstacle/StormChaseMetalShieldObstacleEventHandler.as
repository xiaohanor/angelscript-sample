struct FStormChaseMetalShieldHitByAcidParams
{
	FVector ImpactLocation;
}

UCLASS(Abstract)
class UStormChaseMetalShieldObstacleEventHandler : UHazeEffectEventHandler
{
	UFUNCTION(BlueprintOverride)
	void Setup()
	{
	}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnStartMoving() {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnFinishMoving() {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnHitByAcidProjectile(FStormChaseMetalShieldHitByAcidParams Params) {}
};