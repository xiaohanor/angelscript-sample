UCLASS(Abstract)
class UIslandOverseerSlidingDoorEventHandler : UHazeEffectEventHandler
{
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnOpenStart() {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnOpenStop() {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnCloseStart() {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnCloseStop() {}
}