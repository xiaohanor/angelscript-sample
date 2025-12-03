
struct FTomatoHitEventHandlerParams
{
	UPROPERTY()
	AHazePlayerCharacter Player;
}

UCLASS(Abstract)
class URollingTomatoEventHandler : UHazeEffectEventHandler
{
	// Called when the player gets hit by tomato | Tomatoe-crash-splash
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void TomatoHit(FTomatoHitEventHandlerParams EventParams) {}

}