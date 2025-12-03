
UCLASS(Abstract)
class UIslandStormdrainPerchableAcidBathDroneEventHandler : UHazeEffectEventHandler
{
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnRechargeVFXSpawn() { }

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnStartRecharge() { }

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnBroken() { }

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnRepaired() { }

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnReachedForwards() {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnReachedBackwards() {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnImpact() {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnShieldImpact() {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnPlayerStartedPerching() {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnPlayerStoppedPerching() {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnFlipOverStarted() {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnFlipOverFinished() {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnBrokenLoopingSparks(FVector Pos) {}

};