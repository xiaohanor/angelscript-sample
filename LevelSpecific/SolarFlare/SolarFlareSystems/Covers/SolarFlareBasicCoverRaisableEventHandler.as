UCLASS(Abstract)
class USolarFlareBasicCoverRaisableEventHandler : UHazeEffectEventHandler
{
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnCoverStartMove() {}
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnCoverEndMove() {}
};