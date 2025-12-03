struct FOnBattlefieldCannonShellFired
{
	UPROPERTY()
	FVector ExplosionLocation;
}

UCLASS(Abstract)
class UBattleCruiserCannonEffectHandler : UHazeEffectEventHandler
{
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnShellFired(FOnBattlefieldCannonShellFired Params) {}

}