UCLASS(Abstract)
class ULaunchKiteEffectEventHandler : UHazeEffectEventHandler
{
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void GrappleStarted() {}
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void PlayerEnter() {}
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void PlayerExit() {}
}