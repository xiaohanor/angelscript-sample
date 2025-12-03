struct FSummitStoneBallStatueOnBallSpawnedParams
{
	UPROPERTY()
	int BallsRemaining;
}

UCLASS(Abstract)
class USummitStoneBallStatueEventHandler : UHazeEffectEventHandler
{
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnBallSpawned(FSummitStoneBallStatueOnBallSpawnedParams Params) {}
};