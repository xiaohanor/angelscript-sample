struct FSummitStatueBatteringRamOnHitByRollParams
{
	UPROPERTY()
	FVector HitLocation;
}

struct FSummitStatueBatteringRamOnHitPillarParams
{
	UPROPERTY()
	FVector PillarHitLocation;
}

UCLASS(Abstract)
class USummitStatueBatteringRamEventHandler : UHazeEffectEventHandler
{
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnHitByRoll(FSummitStatueBatteringRamOnHitByRollParams Params) {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnHitPillar(FSummitStatueBatteringRamOnHitPillarParams Params) {}
};