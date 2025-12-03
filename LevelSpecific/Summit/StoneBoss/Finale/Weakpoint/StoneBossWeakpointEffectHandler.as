struct FStoneBossWeakpointHitParams
{
	UPROPERTY()
	FVector Location;

	UPROPERTY()
	FVector Normal;
}

struct FStoneBossWeakpointDestroyedParams
{
	UPROPERTY()
	FVector Location;
}

struct FStoneBossWeakpointDamagedParams
{
	UPROPERTY()
	int DamagedState = 0;

	FStoneBossWeakpointDamagedParams(int NewState)
	{
		DamagedState = NewState;
	}
}


UCLASS(Abstract)
class UStoneBossWeakpointEffectHandler : UHazeEffectEventHandler
{
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnHit(FStoneBossWeakpointHitParams Params) {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnDestroyed(FStoneBossWeakpointDestroyedParams Params) {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnDamaged(FStoneBossWeakpointDamagedParams Params) {}
};