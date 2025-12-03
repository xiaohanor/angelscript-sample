UCLASS(Abstract)
class UPrisonerTransportPlatformEffectEventHandler : UHazeEffectEventHandler
{
	UFUNCTION(BlueprintOverride)
	void Setup()
	{
	}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void StartMoving() {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void StopMoving() {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OpenTopHatches() {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void CloseTopHatches() {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void PrisonerLandingReaction(FPrisonerTransportPlatformEffectEventReactionParams Params) {}
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void PrisonerLandingSkipReaction() {}
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void PrisonerResetReaction() {}
}

struct FPrisonerTransportPlatformEffectEventReactionParams
{
	UPROPERTY()
	AHazePlayerCharacter Player;
}