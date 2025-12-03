UCLASS(Abstract)
class UVillageStealthOgreBoulderEffectEventHandler : UHazeEffectEventHandler
{
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void Thrown() {}
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void KillPlayer() {}
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void Impact() {}
}