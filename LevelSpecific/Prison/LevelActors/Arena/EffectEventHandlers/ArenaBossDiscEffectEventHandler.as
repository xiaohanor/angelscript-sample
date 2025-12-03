UCLASS(Abstract)
class UArenaBossDiscEffectEventHandler : UHazeEffectEventHandler
{
	UFUNCTION(BlueprintOverride)
	void Setup()
	{
	}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void DiscLaunched()
	{
	}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void DiscDestroyed()
	{
	}
}