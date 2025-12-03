class UEnforcerChargeMeleeComponent : UActorComponent
{
	AHazePlayerCharacter TargetPlayer;

	UPROPERTY()
	TSubclassOf<UDamageEffect> DamageEffect;

	UPROPERTY()
	TSubclassOf<UDeathEffect> DeathEffect;
}