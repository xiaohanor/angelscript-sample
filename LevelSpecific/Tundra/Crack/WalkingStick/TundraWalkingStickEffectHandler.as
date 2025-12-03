struct FTundraWalkingStickScreamEffectParams
{
	UPROPERTY()
	FHitResult ScreamHit;
}

struct FTundraWalkingStickStopChargingScreamEffectParams
{
	UPROPERTY()
	bool bScreamSuccessful;
}

UCLASS(Abstract)
class UTundraWalkingStickEffectHandler : UHazeEffectEventHandler
{
	// Gets called when we screamed but hit nothing.
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnScreamNoTarget(FTundraWalkingStickScreamEffectParams Params) {}

	// Gets called when we hit a generic target, something that isn't normally shootable.
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnScreamGenericTarget(FTundraWalkingStickScreamEffectParams Params) {}

	// Gets called when we hit a shootable obstacle
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnScreamObstacleTarget(FTundraWalkingStickScreamEffectParams Params) {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnStartChargingScream() {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnStopChargingScream(FTundraWalkingStickStopChargingScreamEffectParams Params) {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnFailScream() {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnScream() {}
}