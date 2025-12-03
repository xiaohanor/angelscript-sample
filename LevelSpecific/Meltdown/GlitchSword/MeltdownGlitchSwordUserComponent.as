class UMeltdownGlitchSwordUserComponent : UActorComponent
{
	UPROPERTY()
	TSubclassOf<AMeltdownGlitchSword> SwordClass;
	UPROPERTY()
	TSubclassOf<AMeltdownGlitchSwordProjectile> ProjectileClass;
	UPROPERTY()
	TSubclassOf<UMeltdownGlitchShootingCrosshair> CrosshairClass;

	UPROPERTY()
	UForceFeedbackEffect FireForceFeedback;

	UPROPERTY()
	TSubclassOf<UCameraShakeBase> SwordShake;

	AMeltdownGlitchSword Sword;
	uint LastSwordAttackFrame = 0;
	EGlitchSwordAttackType LastSwordAttackDirection;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
	}
};