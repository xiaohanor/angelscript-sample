
struct FOnPotionBrewedParams
{
	FVector PotionLocation;
}

UCLASS(Abstract)
class UMoonMarketWitchCauldronEventHandler : UHazeEffectEventHandler
{
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnBrewingStarted() {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnBrewingFinished(FOnPotionBrewedParams Params) {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnStartRefilling() {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnIngredientAdded() {}
};