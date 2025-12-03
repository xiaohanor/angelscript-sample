struct FVineGemOnCrystalDestroyedParams
{
	UPROPERTY()
	FVector Loc;

	FVineGemOnCrystalDestroyedParams(FVector NewLoc)
	{
		Loc = NewLoc;
	}
}

UCLASS(Abstract)
class UVineGemSpikeEffectHandler : UHazeEffectEventHandler
{
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnCrystalDestroyed(FVineGemOnCrystalDestroyedParams Params) {}
};