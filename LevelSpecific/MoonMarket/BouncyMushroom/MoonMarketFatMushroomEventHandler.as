struct FMoonMarketInteractingPlayerEventParams
{
	UPROPERTY()
	AHazePlayerCharacter InteractingPlayer;

	FMoonMarketInteractingPlayerEventParams(AHazePlayerCharacter InPlayer)
	{
		InteractingPlayer = InPlayer;
	}
}

UCLASS(Abstract)
class UMoonMarketFatMushroomEventHandler : UMoonMarketMushroomPeopleEventHandler
{
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnStartBeingPushed(FMoonMarketInteractingPlayerEventParams Params) {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnStopPushed(FMoonMarketInteractingPlayerEventParams Params) {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnFatMushroomBouncedOn() {}
};