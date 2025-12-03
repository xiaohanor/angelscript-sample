UCLASS(Abstract)
class URubyKnightDoubleInteractEventHandler : UHazeEffectEventHandler
{
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnReact() {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnComplete() {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnRotate() {}
};