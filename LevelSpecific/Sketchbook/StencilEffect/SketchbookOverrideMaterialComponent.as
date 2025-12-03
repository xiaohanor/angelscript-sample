// Because the color red is used as a mask this component can be used to apply a white swatch material on the meshes
class USketchbookOverrideMaterialComponent : UActorComponent
{
	UPROPERTY(EditDefaultsOnly)
	UMaterialInterface Material;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		TArray<UHazeSkeletalMeshComponentBase> SkelMeshes;
		Owner.GetComponentsByClass(UHazeSkeletalMeshComponentBase, SkelMeshes);

		for (auto SkelMesh : SkelMeshes)
		{
			for (int i = 0; i < SkelMesh.NumMaterials; i++)
				SkelMesh.SetMaterial(i, Material);
		}
	}
};