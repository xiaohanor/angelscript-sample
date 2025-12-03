struct FBattlefieldBreakObjectParams
{
	UPROPERTY()
	FVector Location;

	UPROPERTY()
	float ExplosionScale = 1.0;

	UPROPERTY()
	UNiagaraSystem System;
}

UCLASS(Abstract)
class UBattlefieldBreakableObjectEffectHandler : UHazeEffectEventHandler
{
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnObjectBreak(FBattlefieldBreakObjectParams Params) {}
}