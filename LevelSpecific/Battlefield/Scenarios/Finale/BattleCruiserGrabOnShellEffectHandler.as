struct FOnGrabShellFired
{
	UPROPERTY()
	FVector ExplosionLocation;
}

UCLASS(Abstract)
class UBattleCruiserGrabOnShellEffectHandler : UHazeEffectEventHandler
{
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnShellFired(FOnGrabShellFired Params) {}
}