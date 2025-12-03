UCLASS(Abstract)
class UTundra_IcePalace_SlidingIceBlockerEffectHandler : UHazeEffectEventHandler
{
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnStartMoving() {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnStopMoving() {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnFullyExtended() {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnFullyRetracted() {}
}