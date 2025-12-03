struct FMoonMarketFireworkParams
{
	UPROPERTY()
	FVector Location;

	FMoonMarketFireworkParams(FVector NewLocation)
	{
		Location = NewLocation;
	}
}

UCLASS(Abstract)
class UFireworksCartEffectHandler : UHazeEffectEventHandler
{
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnFireworksActivated(FMoonMarketFireworkParams Params) {}
};