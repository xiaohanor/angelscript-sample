
struct FThreeShotEffectEventParams
{
	UPROPERTY()
	AHazePlayerCharacter Player;
	UPROPERTY()
	AHazeActor InteractionActor;
	UPROPERTY()
	UThreeShotInteractionComponent InteractionComponent;
};

UCLASS(Abstract)
class UThreeShotEffectEventHandler : UHazeEffectEventHandler
{

	// Called when the player has started interacting with the three shot interaction.
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode), DisplayName = "Three Shot Activated")
	void Activated(FThreeShotEffectEventParams Params) {}

	// Called when the EnterAnimation is playing and has fully blended in.
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void EnterBlendedIn(FThreeShotEffectEventParams Params) {}

	// Called when the EnterAnimation has finished and is blending out.
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void EnterBlendingOut(FThreeShotEffectEventParams Params) {}

	// Called when the MHAnimation is playing and has fully blended in.
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode), DisplayName = "MH Blended In")
	void MHBlendedIn(FThreeShotEffectEventParams Params) {}

	// Called when the MHAnimation has finished and is blending out.
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode), DisplayName = "MH Blending Out")
	void MHBlendingOut(FThreeShotEffectEventParams Params) {}

	// Called when the ExitAnimation is playing and has fully blended in.
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void ExitBlendedIn(FThreeShotEffectEventParams Params) {}

	// Called when the ExitAnimation has finished and is blending out.
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void ExitBlendingOut(FThreeShotEffectEventParams Params) {}
}