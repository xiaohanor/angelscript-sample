struct FOnLandingSiteBlowParams
{
	UPROPERTY()
	USceneComponent BlowPoint;
}

UCLASS(Abstract)
class UAdultDragonLandingSiteEffectHandler : UHazeEffectEventHandler
{
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnHornBlow(FOnLandingSiteBlowParams Params) {}
}