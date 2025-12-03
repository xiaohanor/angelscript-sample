struct FOnBattlefieldBomberDestroyedEffectParams
{
	UPROPERTY()
	FVector Location;
}

UCLASS(Abstract)
class UBattlefieldSplineBomberEffectHandler : UHazeEffectEventHandler
{
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnBomberDestroyed(FOnBattlefieldBomberDestroyedEffectParams Params) {}
}