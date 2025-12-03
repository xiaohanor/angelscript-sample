UCLASS(Abstract)
class UIslandOverseerPeekBombEventHandler : UHazeEffectEventHandler
{
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnLaunch(FIslandOverseerPeekBombOnLaunchEventData Data) {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnHit(FIslandOverseerPeekBombOnHitEventData Data) {}
}

struct FIslandOverseerPeekBombOnLaunchEventData
{
	UPROPERTY()
	FVector LaunchLocation;

	FIslandOverseerPeekBombOnLaunchEventData(FVector InLaunchLocation)
	{
		LaunchLocation = InLaunchLocation;
	}
}

struct FIslandOverseerPeekBombOnHitEventData
{
	UPROPERTY()
	FHitResult HitResult;

	FIslandOverseerPeekBombOnHitEventData(FHitResult InHitResult)
	{
		HitResult = InHitResult;
	}
}