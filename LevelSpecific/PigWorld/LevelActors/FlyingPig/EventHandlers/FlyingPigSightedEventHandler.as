
struct FFlyingPigSightedEventHandlerParams
{
	UPROPERTY()
	AHazePlayerCharacter Player;
}

UCLASS(Abstract)
class UFlyingPigSightedEventHandler : UHazeEffectEventHandler
{
	// Called when the player looks at pig
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void FlyingPigSighted(FFlyingPigSightedEventHandlerParams EventParams) {}

}