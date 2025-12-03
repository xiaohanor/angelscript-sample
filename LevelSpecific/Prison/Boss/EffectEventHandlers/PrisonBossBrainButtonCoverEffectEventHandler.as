UCLASS(Abstract)
class UPrisonBossBrainButtonCoverEffectEventHandler : UHazeEffectEventHandler
{
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void MagnetBlasted() {}
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OpenCover() {}
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void CloseCover() {}
}