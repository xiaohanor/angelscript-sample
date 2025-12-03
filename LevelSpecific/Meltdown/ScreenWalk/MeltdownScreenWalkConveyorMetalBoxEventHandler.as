UCLASS(Abstract)
class UMeltdownScreenWalkConveyorMetalBoxEventHandler : UHazeEffectEventHandler
{
	UFUNCTION(BlueprintOverride)
	void Setup()
	{
	}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void Impact() {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void CollapseDropDownHit() {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void Explosion() {}
};