UCLASS(Abstract)
class USanctuaryProwlerEventHandler : UHazeEffectEventHandler
{

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void AttackImpact(FSanctuaryProwlerEventAttackImpactParams Params)
	{
	}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void SwapStart()
	{
	}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void SwapEnd()
	{
	}
}

namespace SanctuaryProwlerSettingsEffectEvents
{
	const FName AttackImpact = n"SanctuaryProwler.AttackImpact";
	const FName SwapStart = n"SanctuaryProwler.SwapStart";
	const FName SwapEnd = n"SanctuaryProwler.SwapEnd";
}

struct FSanctuaryProwlerEventAttackImpactParams
{
	UPROPERTY()
	FVector ImpactLocation;

	FSanctuaryProwlerEventAttackImpactParams(FVector ImpactLoc)
	{
		ImpactLocation = ImpactLoc;
	}
}