struct FOnBattlefieldTankCrushParams
{
	UPROPERTY()
	FVector Location;
}

UCLASS(Abstract)
class UBattlefieldFootCrushedTankEffectHandler : UHazeEffectEventHandler
{
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void CrushTank(FOnBattlefieldTankCrushParams Params) {}
}