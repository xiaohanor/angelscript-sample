struct FStormSiegeGuardianTendrilParams
{
	UPROPERTY()
	USceneComponent AttachComponent;
	UPROPERTY()
	AStormSiegeMagicBarrier MagicBarrier;
}

//TODO rework for guardian destruction instead?
UCLASS(Abstract)
class UStormSiegeGuardianEffectHandler : UHazeEffectEventHandler
{
	// UPROPERTY()
	// UNiagaraSystem SystemClass;
	
	// FStormSiegeGuardianTendrilParams TendrilParams;

	// UNiagaraComponent System;

	// UFUNCTION(BlueprintOverride)
	// void Tick(float DeltaTime)
	// {
	// 	if (System != nullptr)
	// 	{
	// 		System.SetNiagaraVariableVec3("BeamStart", TendrilParams.AttachComponent.WorldLocation);
	// 		System.SetNiagaraVariableVec3("BeamEnd", TendrilParams.MagicBarrier.ActorLocation);
	// 	}
	// }

	// UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	// void SpawnTendril(FStormSiegeGuardianTendrilParams Params)
	// {
	// 	TendrilParams = Params;
	// 	System = Niagara::SpawnLoopingNiagaraSystemAttached(SystemClass, TendrilParams.AttachComponent);
	// }

	// UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	// void DestroyTendril()
	// {
	// 	System.DestroyComponent(System);
	// }
}