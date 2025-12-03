UCLASS(Abstract)
class USanctuaryWeeperEffectEventHandler : UHazeEffectEventHandler
{
    UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
    void OnStartDyingFire() {}

    UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
    void OnStartDyingSpike() {}

    UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
    void OnStartDyingSquished() {}

    UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
    void OnFinishDyingFire() {}

    UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
    void OnFinishDyingSpike() {}

    UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
    void OnFinishDyingSquished() {}

    UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
    void OnRespawn() {}

	TArray<UMaterialInterface> DefaultMaterials;

	UFUNCTION(BlueprintPure)
	UHazeCharacterSkeletalMeshComponent GetMesh()
	{
		return Cast<AHazeCharacter>(Owner).Mesh;
	}

	UFUNCTION()
	void SwitchMaterial(UMaterialInterface Material)
	{
		UMaterialInstanceDynamic DynamicMaterial = Material::CreateDynamicMaterialInstance(this, Material);
		bool bSaveDefaultMaterials = (DefaultMaterials.Num() == 0);

		UHazeCharacterSkeletalMeshComponent Mesh = GetMesh();
		for (int i = 0; i < Mesh.GetNumMaterials(); i++)
		{
			if (bSaveDefaultMaterials)
				DefaultMaterials.Add(Mesh.GetMaterial(i));
			Mesh.SetMaterial(i, DynamicMaterial);			
		}
	}

	UFUNCTION()
	void SetDefaultMaterials()
	{
		UHazeCharacterSkeletalMeshComponent Mesh = GetMesh();
		for (int i = 0; i < DefaultMaterials.Num(); i++)
		{
			Mesh.SetMaterial(i, DefaultMaterials[i]);			
		}
	}

}
