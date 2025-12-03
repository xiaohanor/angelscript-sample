class UAISummitMeltMaterialComponent : UActorComponent
{
	TArray<UMaterialInstanceDynamic> MetalMaterials;
	UAISummitTEMPEnemyMeshComponent TempMeshComp;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		TempMeshComp = UAISummitTEMPEnemyMeshComponent::Get(Owner);

		if (TempMeshComp != nullptr)
		{
			for  (int i = 0; i < TempMeshComp.GetNumMaterials(); i++)
			{
				UMaterialInstanceDynamic DynaMat = TempMeshComp.CreateDynamicMaterialInstance(i);
				MetalMaterials.Add(DynaMat);
				TempMeshComp.SetMaterial(i, MetalMaterials[i]);
			}
		}
	}
}