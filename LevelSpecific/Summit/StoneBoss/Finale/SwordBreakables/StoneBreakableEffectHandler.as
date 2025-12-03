struct FDragonSwordBreakableDeathParams
{
	UPROPERTY()
	FVector Location;
}

struct FDragonSwordBreakableHitParams
{
	UPROPERTY()
	FVector Location;

	UPROPERTY()
	float HealthAlpha;
}

UCLASS(Abstract)
class UStoneBreakableEffectHandler : UHazeEffectEventHandler
{
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void Death(FDragonSwordBreakableDeathParams Params) {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void Hit(FDragonSwordBreakableHitParams Params) {}
};