struct FStoneBeastSpawnerParams
{
	UPROPERTY()
	FVector Location;
	
	FStoneBeastSpawnerParams(FVector Loc)
	{
		Location = Loc;
	}
}

UCLASS(Abstract)
class USummitStoneBeastSpawnerEffectHandler : UHazeEffectEventHandler
{
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnDeath(FStoneBeastSpawnerParams Params){}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnRupture(FStoneBeastSpawnerParams Params) {}
};