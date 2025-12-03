struct FGemFloorBreakerOnLogSpawnedParams
{
	UPROPERTY()
	FVector SpawnLocation;
}

struct FGemFloorBreakerOnBoulderSpawnedParams
{
	UPROPERTY()
	FVector SpawnLocation;
}

UCLASS(Abstract)
class USummitLogSpawnerEventHandler : UHazeEffectEventHandler
{
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnLogSpawned(FGemFloorBreakerOnLogSpawnedParams Params)
	{
	}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnBoulderSpawned(FGemFloorBreakerOnBoulderSpawnedParams Params)
	{
	}
};