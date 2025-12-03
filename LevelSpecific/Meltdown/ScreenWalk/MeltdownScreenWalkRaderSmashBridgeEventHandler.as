UCLASS(Abstract)
class UMeltdownScreenWalkRaderSmashBridgeEventHandler : UHazeEffectEventHandler
{
	UFUNCTION(BlueprintOverride)
	void Setup()
	{
	}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void SmashBridge() {}
};