UCLASS(Abstract)
class UMoonMarketPolymorphEventHandler : UHazeEffectEventHandler
{
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void Dash_Started()
	{
	}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void Dash_Stopped()
	{
	}
};