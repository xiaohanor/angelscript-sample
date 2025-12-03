struct FSolarFlareBatteryShieldEffectHandlerParams
{
	UPROPERTY()
	FVector Location;
}

UCLASS(Abstract)
class USolarFlareBatteryShieldEffectHandler : UHazeEffectEventHandler
{
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void ShieldOn(FSolarFlareBatteryShieldEffectHandlerParams Params)
	{
	}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void ShieldImpact(FSolarFlareBatteryShieldEffectHandlerParams Params)
	{
	}
};