class USkylineTorEjectComponent : UActorComponent
{
	UPROPERTY()
	AHazePlayerCharacter PlayerTarget;

	UPROPERTY(EditDefaultsOnly)
	TSubclassOf<UDamageEffect> DamageEffect;

	UPROPERTY(EditDefaultsOnly)
	TSubclassOf<UDeathEffect> DeathEffect;

	UPROPERTY(EditDefaultsOnly)
	UAnimSequence PlayerGrabbedAnim;

	bool AllowEjectAttack;
}