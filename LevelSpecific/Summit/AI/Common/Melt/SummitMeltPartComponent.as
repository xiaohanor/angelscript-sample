class USummitMeltPartComponent : UStaticMeshComponent
{
	TArray<UMaterialInstanceDynamic> MeltingMetalMaterials;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		UMaterialInstanceDynamic MaterialInstance = CreateDynamicMaterialInstance(0);
		for (int i = 0; i < Materials.Num(); i++)
		{
			SetMaterial(i, MaterialInstance);
			MeltingMetalMaterials.Add(MaterialInstance);
		}
	}

	void SetMeltedMaterials(float Blend)
	{
		for(UMaterialInstanceDynamic Metal : MeltingMetalMaterials)
		{
			Metal.SetScalarParameterValue(n"BlendMelt", Blend);
		}
	}

	void SetDissolveMaterials(float Blend)
	{
		for(UMaterialInstanceDynamic Metal : MeltingMetalMaterials)
		{
			Metal.SetScalarParameterValue(n"BlendDissolve", Blend);
		}
	}
}