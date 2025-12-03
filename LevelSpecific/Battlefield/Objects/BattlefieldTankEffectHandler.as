struct FBattlefieldTankFiredParams
{
	UPROPERTY()
	FVector Loc;

	FBattlefieldTankFiredParams(FVector NewLoc)
	{
		Loc = NewLoc;
	}
}

UCLASS(Abstract)
class UBattlefieldTankEffectHandler : UHazeEffectEventHandler
{
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnTankFired(FBattlefieldTankFiredParams Params) {}
};