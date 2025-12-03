struct FOnStormChaseFallingRockParams
{
	UPROPERTY()
	FVector Location;

	FOnStormChaseFallingRockParams(FVector NewLoc)
	{
		Location = NewLoc;
	}
}

UCLASS(Abstract)
class UStormChaseFallingRockObstacleEffectHandler : UHazeEffectEventHandler
{
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnImpact(FOnStormChaseFallingRockParams Params) {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void StartFalling() {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void StopFalling() {}
};