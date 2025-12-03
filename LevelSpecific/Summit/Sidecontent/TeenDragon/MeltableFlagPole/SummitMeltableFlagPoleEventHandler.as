UCLASS(Abstract)
class USummitMeltableFlagPoleEventHandler : UHazeEffectEventHandler
{
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnPoleMelted() {}
};