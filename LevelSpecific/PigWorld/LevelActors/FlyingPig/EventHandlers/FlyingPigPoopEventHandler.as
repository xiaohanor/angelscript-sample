
struct FPoopStepEventHandlerParams
{
	UPROPERTY()
	AHazePlayerCharacter Player;
}

UCLASS(Abstract)
class UFlyingPigPoopEventHandler : UHazeEffectEventHandler
{
	// Called when the player steps in poop
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void PoopStep(FPoopStepEventHandlerParams EventParams) {}
	// Called when the Poop explodes
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void PoopExplode() {}

}