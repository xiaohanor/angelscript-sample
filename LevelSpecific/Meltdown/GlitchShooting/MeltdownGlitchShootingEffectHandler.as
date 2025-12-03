struct FMeltdownGlitchProjectileFireEffectParams
{
	UPROPERTY()
	FVector FireLocation;
	UPROPERTY()
	FVector FireDirection;
};

struct FMeltdownGlitchSwordSwingEffectParams
{
	UPROPERTY()
	EGlitchSwordAttackType AttackType;

	FMeltdownGlitchSwordSwingEffectParams(EGlitchSwordAttackType _AttackType)
	{
		AttackType = _AttackType;
	}
};

UCLASS(Abstract)
class UMeltdownGlitchShootingEffectHandler : UHazeEffectEventHandler
{
	UFUNCTION(BlueprintOverride)
	void Setup()
	{
	}

	// Glitch Sword
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnSwordAttackStarted(FMeltdownGlitchSwordSwingEffectParams Params) {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnProjectileFired(FMeltdownGlitchProjectileFireEffectParams Params) {}
};