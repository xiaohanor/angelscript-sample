UCLASS(Abstract)
class UMoonMarketPotionEventHandler : UHazeEffectEventHandler
{
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnStartFilling() {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnInteractionStarted(FMoonMarketInteractingPlayerEventParams InteractingPlayer) {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnBeingDrunk(FMoonMarketInteractingPlayerEventParams InteractingPlayer) {}
};