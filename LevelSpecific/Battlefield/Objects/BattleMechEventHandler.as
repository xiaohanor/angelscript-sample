struct FBattleMechParams
{
	UPROPERTY()
	USceneComponent FiringComp;

	FBattleMechParams(USceneComponent NewComp)
	{
		FiringComp = NewComp;
	}
}

UCLASS(Abstract)
class UBattleMechEventHandler : UHazeEffectEventHandler
{
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnMechStartLeft(FBattleMechParams Params) {}
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnMechStopLeft() {}
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnMechStartRight(FBattleMechParams Params) {}
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnMechStopRight() {}
};