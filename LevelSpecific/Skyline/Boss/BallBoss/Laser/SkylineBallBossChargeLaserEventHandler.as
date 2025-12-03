struct FSkylineBallBossChargeLaserChangedStateEventHandlerParams
{
	UPROPERTY()
	EBallBossWeakPointState NewState;
}

class USkylineBallBossChargeLaserEventHandler : UHazeEffectEventHandler
{
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void ChangedState(FSkylineBallBossChargeLaserChangedStateEventHandlerParams Params) {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void MioEnterInteract() {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void MioInteractCompleted() {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void MioBladeHit() {}
}
