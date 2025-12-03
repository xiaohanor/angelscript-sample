
struct FGoldenApplePickupEventHandlerParams
{
	UPROPERTY()
	AHazePlayerCharacter Player;
}

UCLASS(Abstract)
class UGoldenAppleEventHandler : UHazeEffectEventHandler
{
	// Called when the player picks up apple
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void ApplePickup(FGoldenApplePickupEventHandlerParams EventParams) {}
}