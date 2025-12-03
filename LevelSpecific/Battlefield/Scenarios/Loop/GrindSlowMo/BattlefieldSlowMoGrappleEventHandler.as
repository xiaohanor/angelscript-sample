UCLASS(Abstract)
class UBattlefieldSlowMoGrappleEventHandler : UHazeEffectEventHandler
{
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnSlowMoStarted() {}
	
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnSlowMoStopped() {}
};