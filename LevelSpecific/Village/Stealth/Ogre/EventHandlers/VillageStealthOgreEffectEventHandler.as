UCLASS(Abstract)
class UVillageStealthOgreEffectEventHandler : UHazeEffectEventHandler
{
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void TurnAround() {}
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void ThrowBoulder() {}
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void BoulderHitPlayer() {}
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void GrabNewBoulder() {}
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void TurnBack() {}
}