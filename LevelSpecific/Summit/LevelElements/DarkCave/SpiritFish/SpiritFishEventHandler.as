UCLASS(Abstract)
class USpiritFishEventHandler : UHazeEffectEventHandler
{
	UFUNCTION(BlueprintOverride)
	void Setup()
	{
	}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void PouncedOn() {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void FishHop() {}
};