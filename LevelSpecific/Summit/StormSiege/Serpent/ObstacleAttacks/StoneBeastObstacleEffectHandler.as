struct FOnStoneBeastObstacleDestructionParams
{
	UPROPERTY()
	FVector Location;
}

UCLASS(Abstract)
class UStoneBeastObstacleEffectHandler : UHazeEffectEventHandler
{
	UFUNCTION(BlueprintOverride)
	void Setup()
	{
	}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnDestruction(FOnStoneBeastObstacleDestructionParams Params)
	{
	}
};