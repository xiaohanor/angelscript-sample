struct FSiegeMagicBeamParams
{
	UPROPERTY()
	FVector Start;

	UPROPERTY()
	FVector End;

	UPROPERTY()
	USceneComponent AttachedLocation;

	UPROPERTY()
	float Width = 10.0;
}

UCLASS(Abstract)
class USiegeMagicBeamEffectHandler : UHazeEffectEventHandler
{
	UPROPERTY()
	UNiagaraSystem Beam;

	UNiagaraComponent BeamComponent;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
	}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void StartBeam(FSiegeMagicBeamParams Params)
	{
		BeamComponent = Niagara::SpawnLoopingNiagaraSystemAttached(Beam, Params.AttachedLocation);
		BeamComponent.SetNiagaraVariableVec3("BeamStart", Params.Start);
		BeamComponent.SetNiagaraVariableVec3("BeamEnd", Params.End);
		BeamComponent.SetNiagaraVariableFloat("BeamWidth", Params.Width);
		// BeamComponent.SetColorParameter(n"Color", FLinearColor::Purple);
	}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void StopBeam()
	{
		BeamComponent.DestroyComponent(this);
	}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void UpdateBeamLocations(FSiegeMagicBeamParams Params)
	{
		PrintToScreen("UpdateBeamLocations");
		BeamComponent.SetNiagaraVariableVec3("BeamStart", Params.Start);
		BeamComponent.SetNiagaraVariableVec3("BeamEnd", Params.End);
		BeamComponent.SetNiagaraVariableFloat("BeamWidth", Params.Width);
		// Debug::DrawDebugLine(Params.Start, Params.End, FLinearColor::Red, 150.0);
	}
};