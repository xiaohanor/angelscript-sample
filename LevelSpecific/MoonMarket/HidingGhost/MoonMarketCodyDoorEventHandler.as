struct FMoonMarketCodyEventData
{
	UPROPERTY()
	bool bIsCody;

	FMoonMarketCodyEventData(bool bSetIsCody)
	{
		bIsCody = bSetIsCody;
	}
}

UCLASS(Abstract)
class UMoonMarketCodyDoorEventHandler : UHazeEffectEventHandler
{
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnDoorOpened(FMoonMarketCodyEventData Params) {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnDoorClosed(FMoonMarketCodyEventData Params) {}
};