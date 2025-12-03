
/**
 * Particles that we spawn ontop of geometry and let them stay there indefinetely until 
 * something (player interaction) triggers them to move - only then do we allow them to be killed.   
 * 
 * Otherwise we'll pause their simulation (not rendering) when player is far away.
 * 
 * Disabling rendering via DisableComponent currently resets the simulation. @TODO: investigate.
 */

UCLASS(Abstract, ComponentWrapperClass)
class APlacedParticles : AHazeActor
{
	UPROPERTY(RootComponent, DefaultComponent, ShowOnActor)
	UNiagaraComponent NiagaraComponent;

	UFUNCTION(BlueprintOverride)
	void ConstructionScript()
	{
		/**
		 * NiagaraComps that are added on the code layer don't auto-activate 
		 * when Construction Scripts runs for some reason, so we do it manually here.
		 */
		NiagaraComponent.DeactivateImmediate();
		NiagaraComponent.ResetSystem();
	}

	UFUNCTION(BlueprintCallable)
	void UpdateCullingDistance(UNiagaraComponent NiagaraComp, UDisableComponent DisableComp)
	{
		// For split screen purposes, we _also_ want to separately turn off rendering (but not simulation)
		// for niagara systems that are outside of disable range for one player but still
		// inside disable range for the other.
		float MaxDistance = NiagaraComp.GetNiagaraCullingMaxDistance();
		DisableComp.AutoDisableRange = MaxDistance;
		NiagaraComp.SetCullDistance(MaxDistance);
	}
}