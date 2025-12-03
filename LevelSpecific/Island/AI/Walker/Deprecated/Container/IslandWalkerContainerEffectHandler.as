UCLASS(Abstract)
class UIslandWalkerContainerEffectHandler : UHazeEffectEventHandler
{
	// The container landed on the ground
    UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
    void OnLand() {}
}