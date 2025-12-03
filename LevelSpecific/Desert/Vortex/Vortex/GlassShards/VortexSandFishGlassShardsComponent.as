event void FVortexSandFishGlassShardsOnVolleyFinished(bool bSuccess);

struct FVortexSandFishGlassShardsVolley
{
	UPROPERTY()
	int NumGlassShards;

	UPROPERTY()
	float Interval;

	FVortexSandFishGlassShardsVolley(int InNumGlassShards, float InInterval)
	{
		NumGlassShards = InNumGlassShards;
		Interval = InInterval;
	}
}

class UVortexSandFishGlassShardsComponent : UActorComponent
{
	UPROPERTY(EditDefaultsOnly)
	TSubclassOf<AVortexSandFishGlassShard> GlassShardClass;

	UPROPERTY()
	FVortexSandFishGlassShardsOnVolleyFinished OnVolleyFinished;

	bool bIsActive = false;
	FVortexSandFishGlassShardsVolley CurrentVolley;
	int TotalSpawnedGlassShards = 0;

	UFUNCTION(BlueprintCallable)
	void StartFiringGlassShards(FVortexSandFishGlassShardsVolley Volley)
	{
		bIsActive = true;
		CurrentVolley = Volley;
	}

	UFUNCTION(BlueprintCallable)
	void StopFiringGlassShards(bool bSuccess)
	{
		bIsActive = false;
		OnVolleyFinished.Broadcast(bSuccess);
	}
};