
struct FOneShotEffectEventParams
{
	UPROPERTY()
	AHazePlayerCharacter Player;
	UPROPERTY()
	AHazeActor InteractionActor;
	UPROPERTY()
	UOneShotInteractionComponent InteractionComponent;
};

UCLASS(Abstract)
class UOneShotEffectEventHandler : UHazeEffectEventHandler
{

	// Called when the player has started interacting with the one shot interaction.
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode), DisplayName = "One Shot Activated")
	void Activated(FOneShotEffectEventParams Params) {}

	// Called when the one shot animation has fully blended in.
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode), DisplayName = "One Shot Blended In")
	void BlendedIn(FOneShotEffectEventParams Params) {}

	// Called when the one shot animation has finished and is blending out.
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode), DisplayName = "One Shot Blending Out")
	void BlendingOut(FOneShotEffectEventParams Params) {}
}