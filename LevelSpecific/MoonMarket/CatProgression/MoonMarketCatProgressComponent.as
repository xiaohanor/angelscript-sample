event void FOnMoonMarketCatProgressionActivated();

class UMoonMarketCatProgressComponent : UActorComponent
{
	FOnMoonMarketCatProgressionActivated OnProgressionActivated;

	void SetProgressionActivated()
	{
		OnProgressionActivated.Broadcast();
	}
};