UCLASS(Abstract)
class USkylineTurretProjectileEffectHandler : UHazeEffectEventHandler
{
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
    void OnTelegraph(FSkylineTurretProjectileOnTelegraphData Data) {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
    void OnImpact() {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
    void OnExpire() {}
}

struct FSkylineTurretProjectileOnTelegraphData
{
	UPROPERTY()
	FVector TargetLocation;
}