UCLASS(Abstract)
class UIslandOverseerRedBlueDoorTargetEventHandler : UHazeEffectEventHandler
{
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnOpenStart() {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnOpenStop() {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnCloseStart() {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnCloseStop() {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnTargetActivated() {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnTargetDeactivated() {}
}