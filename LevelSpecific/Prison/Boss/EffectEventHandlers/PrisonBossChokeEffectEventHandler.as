UCLASS(Abstract)
class UPrisonBossChokeEffectEventHandler : UHazeEffectEventHandler
{
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void StartChoking() {}
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void MagnetBlasted() {}
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void PlayerSuccess() {}
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void PlayerFail() {}
}