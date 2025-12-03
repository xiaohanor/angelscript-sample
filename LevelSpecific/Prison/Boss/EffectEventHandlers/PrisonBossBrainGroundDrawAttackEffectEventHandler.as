UCLASS(Abstract)
class UPrisonBossBrainGroundDrawAttackEffectEventHandler : UHazeEffectEventHandler
{
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void ActivateBeam() {}
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void StartDrawing() {}
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void ShapeCompleted() {}
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void BeamFullyRetracted() {}
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void Dissipate() {}
}