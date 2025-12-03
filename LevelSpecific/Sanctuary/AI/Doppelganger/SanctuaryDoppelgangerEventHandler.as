UCLASS(Abstract)
class USanctuaryDoppelgangerEventHandler : UHazeEffectEventHandler
{

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void AttackImpact(FDoppelgangerEventAttackImpactParams Params)
	{
	}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void Reveal()
	{
	}
}

struct FDoppelgangerEventAttackImpactParams
{
	UPROPERTY()
	FVector ImpactLocation;

	FDoppelgangerEventAttackImpactParams(FVector ImpactLoc)
	{
		ImpactLocation = ImpactLoc;
	}
}
