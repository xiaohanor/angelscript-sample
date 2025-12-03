struct FSummitWardDeathParams
{
	UPROPERTY()
	FVector Location;
	
	UPROPERTY()
	FRotator Rotation;
}

class UAISummitWardEffectsHandler : UHazeEffectEventHandler
{

	UPROPERTY()
	UNiagaraSystem DeathSystem;

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void DestroyWard(FSummitWardDeathParams Params) 
	{
		Niagara::SpawnOneShotNiagaraSystemAtLocation(DeathSystem, Params.Location, Params.Rotation);
	}	
}