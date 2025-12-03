class USummitDecimatorTopdownMeltComponent : USummitMeltComponent
{
	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		Super::BeginPlay();
		
		AHazeActor HazeOwner = Cast<AHazeActor>(Owner);
		
		AAISummitDecimatorTopdown Decimator = Cast<AAISummitDecimatorTopdown>(Owner);
		if(Decimator != nullptr)
		{
			UMaterialInstanceDynamic MaterialInstance = Decimator.PoseableMesh.CreateDynamicMaterialInstance(MeltMaterialIndex);
			if(MaterialInstance != nullptr)
			{
				if (bMeltAllMaterials)
				{
					// Assigns same dynamic material to all materials on the mesh.
					int MaterialsNum = Decimator.Mesh.Materials.Num();
					for (int i = 0; i < MaterialsNum; i++)
					{
						Decimator.Mesh.SetMaterial(i, MaterialInstance);
						MeltingMetalMaterials.Add(MaterialInstance);
					}
				}
				else
				{
					// Only make the specified material index meltable.
					Decimator.Mesh.SetMaterial(MeltMaterialIndex, MaterialInstance);
					MeltingMetalMaterials.Add(MaterialInstance);
				}
			}
		}
	}
}