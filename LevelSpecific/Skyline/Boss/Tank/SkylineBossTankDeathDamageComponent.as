class USkylineBossTankDeathDamageComponent : UActorComponent
{
	UPROPERTY(EditDefaultsOnly)
	TSubclassOf<UDeathEffect> LaserHeavyDeathEffect;
	UPROPERTY(EditDefaultsOnly)
	TSubclassOf<UDeathEffect> LargeObjectDeathEffect;
	UPROPERTY(EditDefaultsOnly)
	TSubclassOf<UDeathEffect> FireSoftDeathEffect;
	UPROPERTY(EditDefaultsOnly)
	TSubclassOf<UDeathEffect> ExplosionDeathEffect;
	UPROPERTY(EditDefaultsOnly)
	TSubclassOf<UDeathEffect> FireImpactDeathEffect;

	UPROPERTY(EditDefaultsOnly)
	TSubclassOf<UDamageEffect> LaserHeavyDamageEffect;
	UPROPERTY(EditDefaultsOnly)
	TSubclassOf<UDamageEffect> LargeObjectDamageEffect;
	UPROPERTY(EditDefaultsOnly)
	TSubclassOf<UDamageEffect> FireSoftDamageEffect;
	UPROPERTY(EditDefaultsOnly)
	TSubclassOf<UDamageEffect> ExplosionDamageEffect;
	UPROPERTY(EditDefaultsOnly)
	TSubclassOf<UDamageEffect> FireImpactDamageEffect;
};