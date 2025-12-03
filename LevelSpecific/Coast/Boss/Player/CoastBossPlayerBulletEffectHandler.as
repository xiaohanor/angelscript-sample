struct FCoastBossPlayerBulletOnShootParams
{
	UPROPERTY()
	USceneComponent Muzzle;
}

struct FCoastBossPlayerBulletOnImpactParams
{
	UPROPERTY()
	FVector HitLocation;

	UPROPERTY()
	USceneComponent PlaneToAttachTo;
}

UCLASS(Abstract)
class UCoastBossPlayerBulletEffectHandler : UHazeEffectEventHandler
{
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnShoot(FCoastBossPlayerBulletOnShootParams Params) {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnImpact(FCoastBossPlayerBulletOnImpactParams Params) {}
}