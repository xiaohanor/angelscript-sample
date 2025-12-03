struct FSolarFlareBatteryPerchEffectHandlerParams
{
	UPROPERTY()
	FVector Location;

	UPROPERTY()
	FVector IndicatorLocation;
}

UCLASS(Abstract)
class USolarFlareBatteryPerchEffectHandler : UHazeEffectEventHandler
{
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void BatteryOff(FSolarFlareBatteryPerchEffectHandlerParams Params) {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void BatteryOn(FSolarFlareBatteryPerchEffectHandlerParams Params) {}
};