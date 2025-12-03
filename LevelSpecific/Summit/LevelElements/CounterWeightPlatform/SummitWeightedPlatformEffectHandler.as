UCLASS(Abstract)
class USummitWeightedPlatformEffectHandler : UHazeEffectEventHandler
{
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnWeightPlatformStartDropped() {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnWeightPlatformReachedEnd() {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnClimbWallStartDrop() {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnClimbWallEndDrop() {}
};