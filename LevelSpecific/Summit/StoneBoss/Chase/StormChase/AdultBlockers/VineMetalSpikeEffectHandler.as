struct FVineGemOnMetalDestroyedParams
{
	UPROPERTY()
	FVector Loc;

	FVineGemOnMetalDestroyedParams(FVector NewLoc)
	{
		Loc = NewLoc;
	}
}

UCLASS(Abstract)
class UVineMetalSpikeEffectHandler : UHazeEffectEventHandler
{
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnMetalDestroyed(FVineGemOnMetalDestroyedParams Params) {}
};