struct FMoonMarketAmbientCritterEventParams
{
	FString CritterName;
}

UCLASS(Abstract)
class UMoonMarketAmbientCritterEventHandler : UHazeEffectEventHandler
{
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnSmallReaction(FMoonMarketAmbientCritterEventParams Params) {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnBigReaction(FMoonMarketAmbientCritterEventParams Params) {}
};