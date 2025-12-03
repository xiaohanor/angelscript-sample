
struct FDoubleInteractionEventParams
{
	UPROPERTY()
	AHazePlayerCharacter Player;
	UPROPERTY()
	AHazeActor InteractionActor;
	UPROPERTY()
	UInteractionComponent InteractionComponent;
};

UCLASS(Abstract)
class UDoubleInteractionEffectEventHandler : UHazeEffectEventHandler
{

	// Called when a player has started interacting with the double interaction.
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode), DisplayName = "Double Interaction Activated")
	void Activated(FDoubleInteractionEventParams Params) {}

	// Called when a player has stopped interacting with the double interaction.
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode), DisplayName = "Double Interaction Deactivated")
	void Deactivated(FDoubleInteractionEventParams Params) {}

	// Called when the EnterAnimation is playing and has fully blended in on a player.
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void EnterBlendedIn(FDoubleInteractionEventParams Params) {}

	// Called when the EnterAnimation has finished and is blending out on a player.
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void EnterBlendingOut(FDoubleInteractionEventParams Params) {}

	// Called when the MHAnimation is playing and has fully blended in on a player.
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode), DisplayName = "MH Blended In")
	void MHBlendedIn(FDoubleInteractionEventParams Params) {}

	// Called when the MHAnimation has been stopped and is blending out on a player.
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode), DisplayName = "MH Blending Out")
	void MHBlendingOut(FDoubleInteractionEventParams Params) {}

	// Called when the CancelAnimation is playing and has fully blended in on a player.
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void CancelBlendedIn(FDoubleInteractionEventParams Params) {}

	// Called when the CancelAnimation has been stopped and is blending out on a player.
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void CancelBlendingOut(FDoubleInteractionEventParams Params) {}

	// Called when the CompletedAnimation is playing and has fully blended in on a player.
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void CompletedBlendedIn(FDoubleInteractionEventParams Params) {}

	// Called when the CompletedAnimation has been stopped and is blending out on a player.
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void CompletedBlendingOut(FDoubleInteractionEventParams Params) {}
}