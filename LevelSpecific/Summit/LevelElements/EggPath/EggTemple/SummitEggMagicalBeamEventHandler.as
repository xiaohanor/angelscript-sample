UCLASS(Abstract)
class USummitEggMagicalBeamEventHandler : UHazeEffectEventHandler
{
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void StartSplineMove() { }
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void StopSplineMove() { }
};