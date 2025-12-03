struct FMeltdownBossTridentSlamHitParams
{
	UPROPERTY()
	FVector HitLocation;
}

UCLASS(Abstract)
class UMeltdownBossPhaseTwoTridentEffectHandler : UHazeEffectEventHandler
{
	UFUNCTION(BlueprintOverride)
	void Setup()
	{
	}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void TridentPhaseStart() {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void TridentPhaseEnd() {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void SharkSummonStart() {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void SharkSummonEnd() {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void TridentSlamStart() {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void TridentSlamHit(FMeltdownBossTridentSlamHitParams HitParams) {}
};