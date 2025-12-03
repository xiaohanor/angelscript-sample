struct FBattlefieldIceSpikeBreakOffParams
{
	UPROPERTY()
	FVector Location;
}

struct FBattlefieldIceSpikeImpactParams
{
	UPROPERTY()
	FVector Location;
}

UCLASS(Abstract)
class UBattlefieldIceSpikeEffectHandler : UHazeEffectEventHandler
{
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnIceSpikeBreak(FBattlefieldIceSpikeBreakOffParams Params) {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnIceSpikeImpact(FBattlefieldIceSpikeImpactParams Params) {}
}