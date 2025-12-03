UCLASS(Abstract)
class UEvergreenSwingingPoleClimbEffectHandler : UHazeEffectEventHandler
{
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnMonkeyAttachToPole() {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnMonkeyJumpOff() {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnStartSwayingInDirection() {}
}