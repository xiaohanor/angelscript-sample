UCLASS(Abstract)
class USummitBouncyBirdNestEggEventHandler : UHazeEffectEventHandler
{
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnEggExploded() {}
};