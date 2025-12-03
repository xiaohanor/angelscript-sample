struct FSolarFlareFinalBridgeEffectParams
{
	UPROPERTY()
	FVector Location;
}

UCLASS(Abstract)
class USolarFlareFinalBridgeEffectHandler : UHazeEffectEventHandler
{
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnFinalBridgeStartMove(FSolarFlareFinalBridgeEffectParams Params) {}
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnFinalBridgeStopMove(FSolarFlareFinalBridgeEffectParams Params) {}
};