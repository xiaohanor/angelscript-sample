class USkylineMaterialInstanceComponent : UActorComponent
{
	TArray<UPrimitiveComponent> PrimitiveComps;
	TMap<UMaterialInterface, UMaterialInstanceDynamic> MIDs;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		Owner.GetComponentsByClass(PrimitiveComps);
		for (auto PrimitiveComp : PrimitiveComps)
		{
			for (int i = 0; i < PrimitiveComp.NumMaterials; i++)
			{
				auto MID = MIDs.FindOrAdd(PrimitiveComp.GetMaterial(i), Material::CreateDynamicMaterialInstance(this, PrimitiveComp.GetMaterial(i)));
				PrimitiveComp.SetMaterial(i, MID);
			}
		}
	}

	UFUNCTION()
	void SetScalarParameterValue(FName ParameterName, float Value)
	{
		for (auto MID : MIDs)
			MID.Value.SetScalarParameterValue(ParameterName, Value);
	}

	UFUNCTION()
	void SetVectorParameterValue(FName ParameterName, FLinearColor Value)
	{
		for (auto MID : MIDs)
			MID.Value.SetVectorParameterValue(ParameterName, Value);
	}
};