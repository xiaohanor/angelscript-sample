struct FGemFloorBreakerOnMagicWaveSpawnedParams
{
	UPROPERTY()
	FVector SpawnLocation;

	FGemFloorBreakerOnMagicWaveSpawnedParams(FVector NewLocation)
	{
		SpawnLocation = NewLocation;
	}
}

UCLASS(Abstract)
class UGemFloorBreakerEventHandler : UHazeEffectEventHandler
{
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnMagicWaveSpawned(FGemFloorBreakerOnMagicWaveSpawnedParams Params) {}
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnLogSpawned(FGemFloorBreakerOnMagicWaveSpawnedParams Params) {}
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnBoulderSpawned(FGemFloorBreakerOnMagicWaveSpawnedParams Params) {}
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnRaiseBarriers(FGemFloorBreakerOnMagicWaveSpawnedParams Params) {}
};