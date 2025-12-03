UCLASS(Abstract)
class UTundra_River_SphereLauncher_Projectile_EffectHandler : UHazeEffectEventHandler
{
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void Break() {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void HitTarget() {}
}