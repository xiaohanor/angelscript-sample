struct FSiegeMagicTrajectoryProjectileFireParams
{
	UPROPERTY()
	FVector Location;
}

struct FSiegeMagicTrajectoryProjectileImpactParams
{
	UPROPERTY()
	FVector Location;

	UPROPERTY()
	FVector Normal;
}

UCLASS(Abstract)
class USiegeMagicTrajectoryProjectileEffectHandler : UHazeEffectEventHandler
{
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void Fire(FSiegeMagicTrajectoryProjectileFireParams Params) {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void Impact(FSiegeMagicTrajectoryProjectileImpactParams Params) {}
}