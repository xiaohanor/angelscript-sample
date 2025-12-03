UCLASS(Abstract)
class USkylineTrashCanEventHandler : UHazeEffectEventHandler
{
	UFUNCTION(BlueprintOverride)
	void Setup()
	{
	}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void HitByKatana() {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void SlingableEnterTrashCan() {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void TrashCanStopSpinning() {}
};