struct FRollotronPlayerEventParams
{
	FRollotronPlayerEventParams(AAIIslandRollotron InRollotron)
	{
		Rollotron = InRollotron;
	}

	UPROPERTY()
	AAIIslandRollotron Rollotron;
}

UCLASS(Abstract)
class UIslandRollotronPlayerEffectHandler : UHazeEffectEventHandler
{
    UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
    void OnTelegraphCharge() {}

    UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
    void OnChargeStart() {}

    UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
    void OnChargeEnd() {}

    UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnDetonated() {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnWaveSpawned() {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
    void OnRollotronSpikesOut(FRollotronPlayerEventParams Params) {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
    void OnRollotronDetonate(FRollotronPlayerEventParams Params) {}
}