struct FSummitDecimatorTopdownPlayerTrapTelegraphParams
{
	FSummitDecimatorTopdownPlayerTrapTelegraphParams(AHazeActor TargetActor)
	{
		Target = TargetActor;
	}

	UPROPERTY()
	AHazeActor Target;
}

UCLASS(Abstract)
class USummitDecimatorTopdownPlayerTrapEffectsHandler : UHazeEffectEventHandler
{
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnCrystalSmashed() {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnMelted() {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnCrystalTrapped() {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnMetalTrapped() {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnTelegraphStarted(FSummitDecimatorTopdownPlayerTrapTelegraphParams Params) {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnTelegraphStopped(FSummitDecimatorTopdownPlayerTrapTelegraphParams Params) {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnTelegraphAborted() {}

}