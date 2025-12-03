
struct FBubbleHintEventHandlerParams
{
	UPROPERTY()
	AHazePlayerCharacter Player;
}

UCLASS(Abstract)
class UBounceBubbleSpawnerEventHandler : UHazeEffectEventHandler
{
	// Called if a player bounces on a bubble
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void BounceOnBubble(FBubbleHintEventHandlerParams EventParams) {}
}