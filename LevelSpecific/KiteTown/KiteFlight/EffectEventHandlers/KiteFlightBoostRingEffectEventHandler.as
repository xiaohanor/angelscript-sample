UCLASS(Abstract)
class UKiteFlightBoostRingEffectEventHandler : UHazeEffectEventHandler
{
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void Boost() {}
}