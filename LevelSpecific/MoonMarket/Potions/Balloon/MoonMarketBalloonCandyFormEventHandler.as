struct FMoonMarketBalloonCandyFormEventData
{
	UPROPERTY()
	AHazePlayerCharacter Player;
}


UCLASS(Abstract)
class UMoonMarketBalloonCandyFormEventHandler : UHazeEffectEventHandler
{
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnInteractionStarted(FMoonMarketBalloonCandyFormEventData Params) {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnEnterBalloonForm(FMoonMarketBalloonCandyFormEventData Params) {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnExitBalloonForm(FMoonMarketBalloonCandyFormEventData Params) {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnBounce(FMoonMarketBalloonCandyFormEventData Params) {}
};