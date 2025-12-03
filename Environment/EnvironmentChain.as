
/**
 * 
 * Niagara chains that can be attached to stuff and that react to forces.
 */

class AEnvironmentChain : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent, ShowOnActor)
	UNiagaraComponent Chains;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		Environment::GetForceEmitter().RegisterChain(this);
	}

	UFUNCTION(BlueprintOverride)
	void EndPlay(EEndPlayReason EndPlayReason)
	{
		Environment::GetForceEmitter().UnregisterChain(this);
	}

	UFUNCTION(BlueprintCallable, Category = "Environment Chain")
	void ApplyShockwaveForce(const FEnvironmentShockwaveForceData& ShockwaveData)
	{
		Chains.SetNiagaraVariableFloat("ShockwaveStrength", ShockwaveData.Strength);
		Chains.SetNiagaraVariableFloat("ShockwaveInnerRadius", ShockwaveData.InnerRadius);
		Chains.SetNiagaraVariableFloat("ShockwaveOuterRadius", ShockwaveData.OuterRadius);
		Chains.SetNiagaraVariablePosition("ShockwavePosition", ShockwaveData.Epicenter);
	}

	UFUNCTION(BlueprintCallable, Category = "Environment Chain")
	void ClearShockwaveForce()
	{
		Chains.SetNiagaraVariableFloat("ShockwaveStrength", 0);
		Chains.SetNiagaraVariableFloat("ShockwaveInnerRadius", 0);
		Chains.SetNiagaraVariableFloat("ShockwaveOuterRadius", 0);
		Chains.SetNiagaraVariablePosition("ShockwavePosition", FVector::ZeroVector);
	}
}