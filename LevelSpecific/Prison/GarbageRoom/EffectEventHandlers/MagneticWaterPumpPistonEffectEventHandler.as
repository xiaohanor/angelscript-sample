UCLASS(Abstract)
class UMagneticWaterPumpPistonEffectEventHandler : UHazeEffectEventHandler
{
	UFUNCTION(BlueprintOverride)
	void Setup()
	{
	}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void StartMagnetizing() {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void StopMagnetizing() {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void MagnetBurstActivated() {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void StartMoving() {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void StopMoving() {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void HitBottom() {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void HitTop() {}
}