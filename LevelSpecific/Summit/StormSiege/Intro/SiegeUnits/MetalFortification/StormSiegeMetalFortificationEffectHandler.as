struct FStormSiegeMetalDestroyedParams
{
	UPROPERTY()
	FVector Location;

	UPROPERTY()
	float Scale = 1.0;
}

struct FStormSiegeMetalRegrowParams
{
	UPROPERTY()
	FVector Location;
}

struct FStormSiegeMetalAcidifiedParams
{
	UPROPERTY()
	USceneComponent AttachComp;
}

struct FStormSiegeMetalPreGrowthParams
{
	UPROPERTY()
	USceneComponent AttachComp;
}

UCLASS(Abstract)
class UStormSiegeMetalFortificationEffectHandler : UHazeEffectEventHandler
{
	UPROPERTY()
	UNiagaraSystem AcidEffectClass;

	UNiagaraComponent AcidEffect;

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnMetalDestroyed(FStormSiegeMetalDestroyedParams Params) {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnMetalRegrow(FStormSiegeMetalRegrowParams Params) {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnMetalAcidifiedActivate(FStormSiegeMetalAcidifiedParams Params)  
	{
		AcidEffect = Niagara::SpawnLoopingNiagaraSystemAttached(AcidEffectClass, Params.AttachComp);
	}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnMetalAcidifiedDeactivate()
	{
		if (AcidEffect != nullptr)
			AcidEffect.DestroyComponent(AcidEffect);
	}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnMetalPreGrowthEffect(FStormSiegeMetalPreGrowthParams Params) {}
}