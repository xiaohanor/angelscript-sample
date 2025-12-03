UCLASS(Abstract)
class USummitDarkCaveMovableClimbSectionEventHandler : UHazeEffectEventHandler
{
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnStatueStartRotation() {}
	
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnStatueStopRotation() {}
};