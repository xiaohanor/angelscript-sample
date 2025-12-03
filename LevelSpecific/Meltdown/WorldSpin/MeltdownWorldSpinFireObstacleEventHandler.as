UCLASS(Abstract)
class UMeltdownWorldSpinFireObstacleEventHandler : UHazeEffectEventHandler
{
	UFUNCTION(BlueprintOverride)
	void Setup()
	{
	}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void StartFire() {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void StopFire() {}
};