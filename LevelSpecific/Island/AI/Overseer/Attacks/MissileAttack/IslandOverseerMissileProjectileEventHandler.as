UCLASS(Abstract)
class UIslandOverseerMissileProjectileEventHandler : UHazeEffectEventHandler
{
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnLaunch(FIslandOverseerMissileProjectileOnLaunchEventData Data) {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnHit(FIslandOverseerMissileProjectileOnHitEventData Data) {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
    void OnTelegraph(FIslandOverseerMissileProjectileOnTelegraphData Data) {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
    void OnExpire() {}
}

struct FIslandOverseerMissileProjectileOnLaunchEventData
{
	UPROPERTY()
	FVector LaunchLocation;

	FIslandOverseerMissileProjectileOnLaunchEventData(FVector InLaunchLocation)
	{
		LaunchLocation = InLaunchLocation;
	}
}

struct FIslandOverseerMissileProjectileOnHitEventData
{
	UPROPERTY()
	FHitResult HitResult;

	FIslandOverseerMissileProjectileOnHitEventData(FHitResult InHitResult)
	{
		HitResult = InHitResult;
	}
}

struct FIslandOverseerMissileProjectileOnTelegraphData
{
	UPROPERTY()
	FVector TargetLocation;
}