UCLASS(Abstract)
class UIslandOverseerWallBombEventHandler : UHazeEffectEventHandler
{
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnLaunch(FIslandOverseerWallBombOnLaunchEventData Data) {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnHit(FIslandOverseerWallBombOnHitEventData Data) {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnDeployed() {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnDestroyed() {}
}

struct FIslandOverseerWallBombOnLaunchEventData
{
	UPROPERTY()
	FVector LaunchLocation;

	FIslandOverseerWallBombOnLaunchEventData(FVector InLaunchLocation)
	{
		LaunchLocation = InLaunchLocation;
	}
}

struct FIslandOverseerWallBombOnHitEventData
{
	UPROPERTY()
	FHitResult HitResult;

	FIslandOverseerWallBombOnHitEventData(FHitResult InHitResult)
	{
		HitResult = InHitResult;
	}
}