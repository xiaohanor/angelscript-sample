UCLASS(Abstract)
class UTundraBossHomingIceChunk_EffectHandler : UHazeEffectEventHandler
{
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnIceChunkSpawned(FTundraBossHomingIceChunkEffectParams Params)
	{
	}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnIceChunkExploded(FTundraBossHomingIceChunkEffectParams Params)
	{
	}
};

struct FTundraBossHomingIceChunkEffectParams
{
	UPROPERTY()
	float Lifetime;

	UPROPERTY()
	FVector ExplosionLocation;
}