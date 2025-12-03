class UPlayerFairyMoveSplineEffectHandler : UHazeEffectEventHandler
{
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnMoveSplineActivated() {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnMoveSplineDeactivated() {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnFairyEnter() {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnFairyExit() {}
}