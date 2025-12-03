struct FSummitPipeDoorLockSelectorUpdateParams
{
	UPROPERTY()
	float Speed;

	FSummitPipeDoorLockSelectorUpdateParams(float NewSpeed)
	{
		Speed = NewSpeed;
	}
}

UCLASS(Abstract)
class USummitPipeDoorLockSelectorEventHandler : UHazeEffectEventHandler
{
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnSelectorStartMoving() {}
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnSelectorStopMoving() {}
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void UpdateSelectorSpeed(FSummitPipeDoorLockSelectorUpdateParams Params) {}
};