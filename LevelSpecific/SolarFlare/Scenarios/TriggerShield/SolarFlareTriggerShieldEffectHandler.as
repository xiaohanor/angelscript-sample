struct FSolarFlareTriggerShieldEffectHandlerParams
{
	UPROPERTY()
	FVector ShieldLocation;

	UPROPERTY()
	AHazePlayerCharacter Player;
}

UCLASS(Abstract)
class USolarFlareTriggerShieldEffectHandler : UHazeEffectEventHandler
{
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnCollect(FSolarFlareTriggerShieldEffectHandlerParams Params) {}
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void TurnedOn(FSolarFlareTriggerShieldEffectHandlerParams Params) {}
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void TurnedOff(FSolarFlareTriggerShieldEffectHandlerParams Params) {}
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void Impact(FSolarFlareTriggerShieldEffectHandlerParams Params) {}
};