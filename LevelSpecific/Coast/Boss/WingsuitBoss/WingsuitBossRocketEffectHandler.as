// This effect handlers events gets called on AWingsuitBossShootAtTargetProjectile, AWingsuitBossProjectile and AHeliosProjectile
UCLASS(Abstract)
class UWingsuitBossRocketEffectHandler : UHazeEffectEventHandler
{
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnRocketFired() {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnRocketExploded() {}
}