
struct FIsInBasketEventHandlerParams
{
	UPROPERTY()
	AHazePlayerCharacter Player;
}

struct FStretchingBasketEventHandlerParams
{
	UPROPERTY()
	int StretchyTimes;
}

UCLASS(Abstract)
class UFlyingPigPlatformEventHandler : UHazeEffectEventHandler
{
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void IsInBasket(FIsInBasketEventHandlerParams EventParams) {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void StretchingWhileBothInBasket(FStretchingBasketEventHandlerParams EventParams) {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void StretchBelowBasketMioNotInBasket(FStretchingBasketEventHandlerParams EventParams) {}
}