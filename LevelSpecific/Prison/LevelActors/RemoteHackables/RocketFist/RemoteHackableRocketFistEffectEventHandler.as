UCLASS(Abstract)
class URemoteHackableRocketFistEffectEventHandler : UHazeEffectEventHandler
{
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void Spawn() {}
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void Hacked() {}
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void Punch() {}
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void HandHackStartCharge() {}
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void HandHackStopCharge() {}
}