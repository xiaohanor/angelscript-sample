UCLASS(Abstract)
class UDarkCaveSpiritStatueEventHandler : UHazeEffectEventHandler
{
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void Destroyed() {}
	
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void Exposed() {}
};