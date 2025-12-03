UCLASS(Abstract)
class UBattlefieldHighFiveSlowMoEventHandler : UHazeEffectEventHandler
{
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnStartSlowMo() {}
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnStopSlowMo() {}
};