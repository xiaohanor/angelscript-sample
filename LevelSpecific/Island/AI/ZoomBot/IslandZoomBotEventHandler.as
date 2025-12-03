struct FZoomBotChargeHitParams
{
	UPROPERTY()
	AHazeActor Target;

	FZoomBotChargeHitParams(AHazeActor HitTarget)
	{
		Target = HitTarget;
	}
}

UCLASS(Abstract)
class UIslandZoomBotEffectHandler : UHazeEffectEventHandler
{

    UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
    void OnTelegraphCharge() {}

    UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
    void OnChargeStart() {}

    UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
    void OnChargeEnd() {}

    UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
    void OnChargeHit(FZoomBotChargeHitParams Params) {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
    void OnShieldBusterStunnedStart() {}

    UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
    void OnShieldBusterStunnedEnd() {}
}