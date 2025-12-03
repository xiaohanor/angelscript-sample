UCLASS(Abstract)
class USkylineEnforcerRifleProjectileEffectEventHandler : UHazeEffectEventHandler
{
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
    void OnPrime() {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
    void OnLaunch() {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
    void OnDeflected() {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
    void OnImpact(FSkylineEnforcerRifleProjectileOnImpactData Data) {}

	UFUNCTION(BlueprintPure)
	AActor GetLaunchingWeapon()
	{
		return UBasicAIWeaponWielderComponent::Get(UBasicAIProjectileComponent::Get(Owner).Launcher).Weapon;
	}
}

struct FSkylineEnforcerRifleProjectileOnImpactData
{
	FHitResult HitResult;
}