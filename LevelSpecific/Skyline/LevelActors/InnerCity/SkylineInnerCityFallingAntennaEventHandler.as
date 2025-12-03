UCLASS(Abstract)
class USkylineInnerCityFallingAntennaEventHandler : UHazeEffectEventHandler
{
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnStartFall() {}
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnGroundImpact() {}
}