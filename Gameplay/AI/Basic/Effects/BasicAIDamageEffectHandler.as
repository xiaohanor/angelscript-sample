UCLASS(Abstract)
class UBasicAIDamageEffectHandler : UHazeEffectEventHandler
{
    // The owner died (BasicAIDamage.OnDeath)
    UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
    void OnDeath() {}

	// The owner died (BasicAIDamage.OnDamage)
    UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
    void OnDamage() {}
}