UCLASS(Abstract)
class UDarkProjectileEventHandler : UHazeEffectEventHandler
{

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void Hit(FDarkProjectileHitData HitData) { }
	
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void Launch(FDarkProjectileLaunchData LaunchData) { }
	
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void Activated() { }

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void Deactivated() { }
}