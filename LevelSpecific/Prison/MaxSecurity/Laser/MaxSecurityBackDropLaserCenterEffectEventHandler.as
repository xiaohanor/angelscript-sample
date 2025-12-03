UCLASS(Abstract)
class UMaxSecurityBackDropLaserCenterEffectEventHandler : UHazeEffectEventHandler
{
	UFUNCTION(BlueprintOverride)
	void Setup()
	{
	}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void StartSpinning() {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void LasersRevealing() {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void LasersRetracting() {}
}