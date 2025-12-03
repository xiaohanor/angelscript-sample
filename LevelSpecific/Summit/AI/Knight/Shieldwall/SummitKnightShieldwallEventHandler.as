UCLASS(Abstract)
class USummitKnightShieldwallEventHandler : UHazeEffectEventHandler
{
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnRaiseWall(){};
};