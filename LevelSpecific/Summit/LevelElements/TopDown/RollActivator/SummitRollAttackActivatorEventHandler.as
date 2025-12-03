UCLASS(Abstract)
class USummitRollAttackActivatorEventHandler : UHazeEffectEventHandler
{
	UFUNCTION(BlueprintOverride)
	void Setup()
	{
	}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnActivated(FRollParams Params)
	{
	}
};