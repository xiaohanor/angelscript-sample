class UEnforcerRifleComponent : UEnforcerWeaponComponent
{
	UPROPERTY()
	TSubclassOf<UDamageEffect> DamageEffect;

	UPROPERTY()
	TSubclassOf<UDeathEffect> DeathEffect;
}