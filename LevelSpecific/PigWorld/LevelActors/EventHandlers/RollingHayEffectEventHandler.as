UCLASS(Abstract)
class URollingHayEffectEventHandler : UHazeEffectEventHandler
{
	UFUNCTION(BlueprintOverride)
	void Setup()
	{
	}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void PlayerCaught() {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void PlayerReleased() {}
}