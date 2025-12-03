struct FMeltdownScreenWalkHookSpot
{
	FMeltdownScreenWalkHookSpot(USceneComponent _Hook)
	{
		Hook = _Hook;
	}


	UPROPERTY()
	USceneComponent Hook;
}

UCLASS(Abstract)
class UMeltdownScreenWalkMineCartEventHandler : UHazeEffectEventHandler
{
	UFUNCTION(BlueprintOverride)
	void Setup()
	{
	}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void StompImpact(FMeltdownScreenWalkHookSpot Params) {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void StartSparks(FMeltdownScreenWalkHookSpot Params) {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void StopSparks() {}
};