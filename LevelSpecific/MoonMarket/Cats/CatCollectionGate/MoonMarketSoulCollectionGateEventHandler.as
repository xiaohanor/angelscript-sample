struct FMoonMarketSoulCollectionGateParams
{
	UPROPERTY()
	FVector Location;

	FMoonMarketSoulCollectionGateParams(FVector NewLocation)
	{
		Location = NewLocation;
	}
}

UCLASS(Abstract)
class UMoonMarketSoulCollectionGateEventHandler : UHazeEffectEventHandler
{
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnKeysRevealed(FMoonMarketSoulCollectionGateParams Params) {}
};