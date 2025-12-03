UCLASS(Abstract)
class USummitExplodyFruitWallEventHandler : UHazeEffectEventHandler
{
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnWallExploded() {}
};