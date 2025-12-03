struct FSummitRollingGongOnHitByRollParams
{
	UPROPERTY()
	USceneComponent GongMeshRoot;
}

UCLASS(Abstract)
class USummitRollingGongEventHandler : UHazeEffectEventHandler
{
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnHitByRoll(FSummitRollingGongOnHitByRollParams Params) {}
};