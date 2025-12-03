class UGarbageDispenserEventHandler : UHazeEffectEventHandler
{
    UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
    void StartOpening() {}

    UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
    void StopOpening() {}

    UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
    void StartDroppingGarbage() {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
    void StopDroppingGarbage() {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
    void StartClosing() {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
    void StopClosing() {}
}