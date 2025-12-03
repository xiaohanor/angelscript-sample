UCLASS(Abstract)
class USummitCrystalSkullProjectileEventHandler : UHazeEffectEventHandler
{
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnLaunch() {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnExplode() {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnExpireNoExplosion() {}
}

