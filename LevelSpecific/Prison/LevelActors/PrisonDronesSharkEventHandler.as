UCLASS(Abstract)
class UPrisonDronesSharkEventHandler : UHazeEffectEventHandler
{
	UFUNCTION(BlueprintOverride)
	void Setup()
	{
	}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void SharkStartEvent() {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void SharkBiteEvent() {}
};