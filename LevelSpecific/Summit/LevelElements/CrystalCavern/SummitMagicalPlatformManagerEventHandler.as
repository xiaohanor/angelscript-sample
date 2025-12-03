struct FSummitMagicalPlatformStartMoveParams
{
	UPROPERTY()
	AActor TargetActor;

	UPROPERTY()
	UNiagaraComponent EffectComp;

	UPROPERTY()
	UStaticMeshComponent MeshComp;

	FSummitMagicalPlatformStartMoveParams(AActor Target, UNiagaraComponent Comp, UStaticMeshComponent Platform)
	{
		TargetActor = Target;
		EffectComp = Comp;
		MeshComp = Platform;
	}
}

struct FSummitMagicalPlatformProgressionParams
{
	UPROPERTY()
	AActor TargetActor;

	UPROPERTY()
	float Progression;

	UPROPERTY()
	UNiagaraComponent EffectComp;

	UPROPERTY()
	UStaticMeshComponent MeshComp;

	FSummitMagicalPlatformProgressionParams(AActor Target, float CurrentProgress, UNiagaraComponent Comp, UStaticMeshComponent Platform)
	{
		TargetActor = Target;
		Progression = CurrentProgress;
		EffectComp = Comp;
		MeshComp = Platform;
	}
}

struct FSummitMagicalPlatformStopMoveParams
{
	UPROPERTY()
	AActor TargetActor;

	UPROPERTY()
	UNiagaraComponent EffectComp;

	UPROPERTY()
	UStaticMeshComponent MeshComp;

	FSummitMagicalPlatformStopMoveParams(AActor Target, UNiagaraComponent Comp, UStaticMeshComponent Platform)
	{
		TargetActor = Target;
		EffectComp = Comp;
		MeshComp = Platform;
	}
}

struct FSummitPlatformMaterialDynamicData
{
	UPROPERTY()
	UStaticMeshComponent MeshComp;
	UPROPERTY()
	UMaterialInstanceDynamic DynamicMaterial;
}

UCLASS(Abstract)
class USummitMagicalPlatformManagerEventHandler : UHazeEffectEventHandler
{
	UPROPERTY()
	TArray<FSummitPlatformMaterialDynamicData> DynamicMaterialData;

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void StartMoving(FSummitMagicalPlatformStartMoveParams Params) {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void StartMoveDown() {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void MoveProgression(FSummitMagicalPlatformProgressionParams Params) {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void StopMoving(FSummitMagicalPlatformStopMoveParams Params) {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void StopOverlay() {}


	UFUNCTION()
	void SetOverlayMaterial(UStaticMeshComponent MeshComp, UMaterialInterface Material)
	{
		if (DynamicMaterialData.Num() > 0)
		{
			for (FSummitPlatformMaterialDynamicData& Data : DynamicMaterialData)
			{
				if (Data.MeshComp == MeshComp)
					return;
			}
		}

		FSummitPlatformMaterialDynamicData NewData;
		NewData.MeshComp = MeshComp;
		NewData.DynamicMaterial = MeshComp.CreateDynamicMaterialInstance(0);
		NewData.DynamicMaterial = Material::CreateDynamicMaterialInstance(NewData.MeshComp, Material);
		NewData.MeshComp.SetOverlayMaterial(NewData.DynamicMaterial);
		DynamicMaterialData.AddUnique(NewData);
	}

	UFUNCTION()
	void ApplyOpacity(float Alpha)
	{
		for (FSummitPlatformMaterialDynamicData& Data : DynamicMaterialData)
		{
			Data.DynamicMaterial.SetScalarParameterValue(n"GLOBAL_Opacity", Alpha);
		}
	}
};