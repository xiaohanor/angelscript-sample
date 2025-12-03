class UIslandOverseerLaserAttackComponent : UActorComponent
{
	UPROPERTY()
	TSubclassOf<UDeathEffect> DeathEffect;
	UPROPERTY()
	TSubclassOf<UDamageEffect> DamageEffect;
}