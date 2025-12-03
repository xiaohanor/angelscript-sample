UCLASS(Abstract)
class USketchbookEnemyEventHandler : UHazeEffectEventHandler
{
	UFUNCTION(BlueprintOverride)
	void Setup()
	{
	}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnKilledMelee(){}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnKilledBow(){}
};