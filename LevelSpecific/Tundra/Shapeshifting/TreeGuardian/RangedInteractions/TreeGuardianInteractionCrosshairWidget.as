UCLASS(Abstract)
class UTundraPlayerTreeGuardianRangedInteractionCrosshairWidget : UTargetableWidget
{
	// Called when we start looking at a TreeGuardian ranged interact.
	UFUNCTION(BlueprintEvent)
	void OnStartLookingAtInteract(ETundraTreeGuardianRangedInteractionType InteractionType, UTundraTreeGuardianRangedInteractionTargetableComponent Targetable) {}

	// Called when we stop looking at a TreeGuardian ranged interact.
	UFUNCTION(BlueprintEvent)
	void OnStopLookingAtInteract(ETundraTreeGuardianRangedInteractionType InteractionType, UTundraTreeGuardianRangedInteractionTargetableComponent Targetable) {}

	// Called when we press the interact button and start interacting with a TreeGuardian ranged interact.
	UFUNCTION(BlueprintEvent)
	void OnInteractStart(ETundraTreeGuardianRangedInteractionType InteractionType, UTundraTreeGuardianRangedInteractionTargetableComponent Targetable) {}

	// Called when we press cancel and exit the TreeGuardian ranged interact.
	UFUNCTION(BlueprintEvent)
	void OnInteractStop(ETundraTreeGuardianRangedInteractionType InteractionType, UTundraTreeGuardianRangedInteractionTargetableComponent Targetable) {}
}