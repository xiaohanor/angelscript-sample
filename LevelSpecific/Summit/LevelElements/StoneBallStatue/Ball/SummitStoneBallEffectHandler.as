struct FSummitStoneBallLandedOnGroundParams
{
	UPROPERTY()
	FVector LandLocation;
}

struct FSummitStoneBallOnExplodedNearWallParams
{
	UPROPERTY()
	AActor WallActor;
}

UCLASS(Abstract)
class USummitStoneBallEffectHandler : UHazeEffectEventHandler
{
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnBallBecameAirborne() {};

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnBallLandedOnGround(FSummitStoneBallLandedOnGroundParams Params) {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnBallExploded() {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnBallExplodedNearWall(FSummitStoneBallOnExplodedNearWallParams Params) {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnBallFuseLit() {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnRespawned() {}
};