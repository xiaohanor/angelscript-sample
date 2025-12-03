UCLASS(Abstract)
class USummitCrystalSkullEventHandler : UHazeEffectEventHandler
{
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnEvadeDash() {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnTelegraphArcAttack() {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnTelegraphMineLaying() {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnLayMine() {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnTelegraphCritterSpawn() {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnSmashed() {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnForceFieldCollapsing() {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnForceFieldCollapsed() {}
}


