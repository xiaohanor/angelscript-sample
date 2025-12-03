UCLASS(Abstract)
class USummitBallFlyerEventsHandler : UHazeEffectEventHandler
{
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnDie() {};
};