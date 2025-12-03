UCLASS(Abstract)
class USkylinePVPEffectHandler : UHazeEffectEventHandler
{
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void HitByOtherPlayer() {}
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void KilledByOtherPlayer() {}
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void RespawnedAfterKilledByOtherPlayer() {}
};