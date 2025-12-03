struct FSummitFruitPressDragonStatueParams
{
	UPROPERTY()
	FVector Location;

	FSummitFruitPressDragonStatueParams(FVector NewLocation)
	{
		Location = NewLocation;
	}
}

UCLASS(Abstract)
class USummitFruitPressDragonStatueEffectHandler : UHazeEffectEventHandler
{
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnLeftWingStartMoving(FSummitFruitPressDragonStatueParams Params) {}
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnLeftWingStopMoving(FSummitFruitPressDragonStatueParams Params) {}
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnRightWingStartMoving(FSummitFruitPressDragonStatueParams Params) {}
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnRightWingStopMoving(FSummitFruitPressDragonStatueParams Params) {}
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnWingsStartMoving(FSummitFruitPressDragonStatueParams Params) {}
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnWingsStoppedMoving(FSummitFruitPressDragonStatueParams Params) {}
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnStatueStartRotating() {}
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnStatueStopRotating() {}
};