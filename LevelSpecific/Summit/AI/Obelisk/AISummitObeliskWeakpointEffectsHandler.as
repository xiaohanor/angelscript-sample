struct FSummitWeakpointDeathParams
{
	UPROPERTY()
	FVector Location;
	
	UPROPERTY()
	FRotator Rotation;
}

class UAISummitObeliskWeakpointEffectsHandler : UHazeEffectEventHandler
{

	UPROPERTY()
	UNiagaraSystem DeathSystem;

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void DestroyWeakpoint(FSummitWeakpointDeathParams Params) 
	{
		Niagara::SpawnOneShotNiagaraSystemAtLocation(DeathSystem, Params.Location, Params.Rotation);
	}	
}