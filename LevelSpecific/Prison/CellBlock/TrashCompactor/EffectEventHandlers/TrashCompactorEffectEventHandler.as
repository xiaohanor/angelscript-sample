UCLASS(Abstract)
class UTrashCompactorEffectEventHandler : UHazeEffectEventHandler
{
	UFUNCTION(BlueprintOverride)
	void Setup()
	{
	}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void RevealCrusher() {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void FullyRevealed() {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void StartCrushing() {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OpenHatch(FTrashCompactorHatchParams Hatch) {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void CloseHatch(FTrashCompactorHatchParams Hatch) {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void PushedByMagnet() {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void StopCrushing() {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void StartFinalCrush() {}
}

struct FTrashCompactorHatchParams
{
	UPROPERTY()
	USceneComponent HatchRoot;

	UPROPERTY()
	int HatchIndex = -1;
}