struct FStormSiegeRockSpikeDustParams
{
	UPROPERTY()
	FVector Location;

	UPROPERTY()
	USceneComponent AttachComp;

	UPROPERTY()
	float Radius = 1500.0;
}

UCLASS(Abstract)
class UStormSiegeRockSpikeEffectHandler : UHazeEffectEventHandler
{
	UPROPERTY()
	UNiagaraSystem DustSystem;

	UNiagaraComponent DustComponent;

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void StartFallingDust(FStormSiegeRockSpikeDustParams Params) 
	{
		DustComponent = Niagara::SpawnOneShotNiagaraSystemAtLocation(DustSystem, Params.Location);
		
		if (DustComponent != nullptr)
			DustComponent.SetNiagaraVariableFloat("Radius", Params.Radius);
	}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void EndFallingDust() 
	{
		if (DustComponent != nullptr)
			DustComponent.DestroyComponent(this);
	}
}