UCLASS(Abstract)
class UEnforcerJetpackEffectHandler : UHazeEffectEventHandler
{
	UPROPERTY(BlueprintReadOnly)
	UNiagaraComponent LeftEngineFX;

	UPROPERTY(BlueprintReadOnly)
	UNiagaraComponent RightEngineFX;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		TArray<UNiagaraComponent> Effects;
		Owner.GetComponentsByClass(Effects);
		for (UNiagaraComponent Effect : Effects)
		{
			if (Effect == nullptr)
				continue;
			if (Effect.AttachSocketName == n"VFX_JetpackR")
				RightEngineFX = Effect;
			if (Effect.AttachSocketName == n"VFX_JetpackL")
				LeftEngineFX = Effect;
		}
	}

    // Enforcer jetpack starts up (EnforcerJetpack.JetpackStart)
    UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
    void JetpackStart() {}

	// Enforcer travels with jetpack (EnforcerJetpack.JetpackTravel)
    UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
    void JetpackTravel() {}

	// Enforcer jetpack turns off (EnforcerJetpack.JetpackEnd)
    UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
    void JetpackEnd() {}

    UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
    void OnHitBillboard(FJetpackBillboardParams Params) {}

    UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
    void OnLeaveBillboard(FJetpackBillboardParams Params) {}

    UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
    void OnTelegraphBillboardExplosion(FJetpackBillboardParams Params) {}

    UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
    void OnExplodeAtBillboard(FJetpackBillboardParams Params) {}
}

struct FJetpackBillboardParams
{
	UPROPERTY(BlueprintReadOnly, Transient)
	ASkylineJetpackCombatZone BillboardZone;

	FJetpackBillboardParams(ASkylineJetpackCombatZone Zone)
	{
		BillboardZone = Zone;
	}
}