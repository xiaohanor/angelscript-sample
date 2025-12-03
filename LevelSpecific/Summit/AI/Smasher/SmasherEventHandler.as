UCLASS(Abstract)
class USmasherEventHandler : UHazeEffectEventHandler
{
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnSpawn() {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void AttackTelegraph() {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void AttackStart() {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void AttackImpact(FSmasherEventAttackImpactParams Params) {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void AttackCompleted() {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void DigDownStart(FSmasherEventDigParams Params) {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void DigDownCompleted(FSmasherEventDigParams Params) {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void DigAppearStart(FSmasherEventDigParams Params) {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void DigAppearCompleted(FSmasherEventDigParams Params) {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnArmorMelted() {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnArmorRestored() {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnDeath() {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnRollAttackKnockback(FSmasherEventOnRollAttackKnockbackParams Params) {}
}

struct FSmasherEventOnRollAttackKnockbackParams
{
	UPROPERTY()
	FVector ImpactLocation;

	FSmasherEventOnRollAttackKnockbackParams(FVector ImpactLoc)
	{
		ImpactLocation = ImpactLoc;
	}
}

struct FSmasherEventAttackImpactParams
{
	UPROPERTY()
	FVector ImpactLocation;

	FSmasherEventAttackImpactParams(FVector ImpactLoc)
	{
		ImpactLocation = ImpactLoc;
	}
}

struct FSmasherEventDigParams
{
	UPROPERTY()
	FVector StartLocation;

	UPROPERTY()
	FVector EndLocation;

	FSmasherEventDigParams(FVector InStartLocation, FVector InEndLocation)
	{
		StartLocation = InStartLocation;
		EndLocation = InEndLocation;
	}
}