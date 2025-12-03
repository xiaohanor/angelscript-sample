UCLASS(Abstract)
class UPrisonBossVolleyEffectEventHandler : UHazeEffectEventHandler
{
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void Primed() {}
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void Launched() {}
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void Impact() {}
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void DissipateMidair() {}
}