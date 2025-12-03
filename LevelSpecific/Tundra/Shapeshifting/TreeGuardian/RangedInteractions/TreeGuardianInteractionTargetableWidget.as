UCLASS(Abstract)
class UTundraPlayerTreeGuardianRangedInteractionTargetableWidget : UTargetableWidget
{
	uint LastFrameWasPrimaryTarget;

	UFUNCTION(BlueprintEvent)
	void OnStartLookingAtInteract(ETundraTreeGuardianRangedInteractionType InteractionType, const UTundraTreeGuardianRangedInteractionTargetableComponent Targetable) {}

	UFUNCTION(BlueprintEvent)
	void OnStopLookingAtInteract(ETundraTreeGuardianRangedInteractionType InteractionType, const UTundraTreeGuardianRangedInteractionTargetableComponent Targetable) {}

	bool WasPrimaryTarget() const
	{
		return LastFrameWasPrimaryTarget >= Time::FrameNumber - 1;
	}
}