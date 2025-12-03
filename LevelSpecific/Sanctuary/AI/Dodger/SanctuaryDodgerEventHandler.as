

UCLASS(Abstract)
class USanctuaryDodgerEventHandler : UHazeEffectEventHandler
{

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void StartDodge() {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
    void OnRangedAttackTelegraphStart() {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
    void OnRangedAttackTelegraphStop() {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
    void OnRangedAttackStart() {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
    void OnTelegraphCharge() {}

    UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
    void OnChargeStart() {}

    UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
    void OnChargeEnd() {}

    UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
    void OnChargeHit(FSanctuaryDodgerChargeHitParams Params) {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
    void OnGrabDamage(FSanctuaryDodgerGrabDamageParams Params) {}
}

struct FSanctuaryDodgerChargeHitParams
{
	UPROPERTY()
	AHazeActor Target;

	FSanctuaryDodgerChargeHitParams(AHazeActor HitTarget)
	{
		Target = HitTarget;
	}
}

struct FSanctuaryDodgerGrabDamageParams
{
	UPROPERTY()
	AHazeActor Target;

	FSanctuaryDodgerGrabDamageParams(AHazeActor DamageTarget)
	{
		Target = DamageTarget;
	}
}