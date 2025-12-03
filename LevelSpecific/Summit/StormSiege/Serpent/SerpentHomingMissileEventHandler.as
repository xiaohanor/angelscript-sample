struct FSerpentHomingMissileStartParams
{
	UPROPERTY()
	FVector Location;
}

struct FSerpentHomingMissileEndParams
{
	UPROPERTY()
	FVector Location;
}

struct FSerpentHomingMissileImpactParams
{
	UPROPERTY()
	FVector Location;

	UPROPERTY()
	FVector Normal;
}

UCLASS(Abstract)
class USerpentHomingMissileEventHandler : UHazeEffectEventHandler
{
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnStart(FSerpentHomingMissileStartParams Params){}

	//Probably not necessary, but here just in case
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnImpact(FSerpentHomingMissileImpactParams Params){}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnEnd(FSerpentHomingMissileEndParams Params) {}
};