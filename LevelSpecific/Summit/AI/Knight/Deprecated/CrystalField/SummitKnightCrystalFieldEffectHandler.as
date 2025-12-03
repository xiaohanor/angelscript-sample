UCLASS(Abstract)
class USummitKnightCrystalFieldEffectHandler : UHazeEffectEventHandler
{
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnFieldSpawned() {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnFieldUnspawned() {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnFieldCompleted() {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnFieldBreak() {}
}