UCLASS(Abstract)
class UFallingPrinceEventHandler : UHazeEffectEventHandler
{
	UFUNCTION(BlueprintOverride)
	void Setup()
	{
	}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void ArrowHit() {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void Landed() {}
};