UCLASS(Abstract)
class ULaunchKitePlayerEffectEventHandler : UHazeEffectEventHandler
{
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void GrappleStarted() {}
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void EnterTunnel() {}
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void ExitTunnel() {}
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void StartFlight() {}
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void StopFlight() {}
}