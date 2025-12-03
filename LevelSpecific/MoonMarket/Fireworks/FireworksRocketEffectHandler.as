struct FMoonMarketFireworkRocketParams
{
	UPROPERTY()
	FVector Location;

	UPROPERTY()
	bool bHitSomething;

	FMoonMarketFireworkRocketParams(FVector NewLocation, bool bHit)
	{
		Location = NewLocation;
		bHitSomething = bHit;
	}
}

UCLASS(Abstract)
class UFireworksRocketEffectHandler : UHazeEffectEventHandler
{
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnPickedUp(FMoonMarketInteractingPlayerEventParams Params) {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnLaunched(FMoonMarketInteractingPlayerEventParams Params) {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnRocketExplode(FMoonMarketFireworkRocketParams Params) {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void UpdateRocketLocationMoved(FMoonMarketFireworkRocketParams Params) {}
};