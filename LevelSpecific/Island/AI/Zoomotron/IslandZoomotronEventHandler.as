struct FZoomotronChargeHitParams
{
	UPROPERTY()
	AHazeActor Target;

	FZoomotronChargeHitParams(AHazeActor HitTarget)
	{
		Target = HitTarget;
	}
}

UCLASS(Abstract)
class UIslandZoomotronEffectHandler : UHazeEffectEventHandler
{

    UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
    void OnTelegraphCharge() {}

    UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
    void OnChargeStart() {}

    UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
    void OnChargeEnd() {}

    UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
    void OnChargeHit(FZoomotronChargeHitParams Params) {}
}