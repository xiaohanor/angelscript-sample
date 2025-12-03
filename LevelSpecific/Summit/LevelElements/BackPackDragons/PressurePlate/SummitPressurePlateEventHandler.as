UCLASS(Abstract)
class USummitPressurePlateEventHandler : UHazeEffectEventHandler
{
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnButtonStartedGoingDown() {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnButtonStoppedGoingDown() {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnButtonStartedGoingUp() {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnButtonStoppedGoingUp() {}
};