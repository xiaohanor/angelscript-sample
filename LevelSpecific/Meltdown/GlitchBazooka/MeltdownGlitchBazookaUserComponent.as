UCLASS(Abstract)
class UMeltdownGlitchBazookaUserComponent : UActorComponent
{
	UPROPERTY()
	TSubclassOf<AMeltdownGlitchBazooka> SwordClass;
	UPROPERTY()
	TSubclassOf<AMeltdownGlitchBazookaProjectile> ProjectileClass;
	UPROPERTY()
	TSubclassOf<UMeltdownGlitchShootingCrosshair> CrosshairClass;

	AMeltdownGlitchBazooka Bazooka;
	
	UPROPERTY()
	UForceFeedbackEffect BazookaForceFeedback;
	UPROPERTY()
	TSubclassOf<UCameraShakeBase> BazookaShake;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
	}
};