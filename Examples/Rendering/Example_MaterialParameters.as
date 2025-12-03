UCLASS()
class AExample_MaterialParameters : AActor
{
	UPROPERTY(EditAnywhere)
	UStaticMeshComponent StaticMeshComponent;

	UPROPERTY(EditAnywhere)
	UMaterialInterface MaterialInterface;

	UPROPERTY(EditAnywhere)
	UTexture2D MyTexture;

    UFUNCTION(BlueprintOverride)
	void BeginPlay()
    {
		// By far the easiest way to set Material Parameters is to do it directly on the static mesh component.
		StaticMeshComponent.SetScalarParameterValueOnMaterials(n"ScalarParameterName", 1.0f);
		StaticMeshComponent.SetColorParameterValueOnMaterials(n"VectorParameterName", FLinearColor(1, 2, 3, 4));


		// Alternatively, you can make a Dynamic Material instance from the mesh and set parameters on it.
		int MaterialIndex = 0;
		UMaterialInstanceDynamic MaterialInstanceDynamic = StaticMeshComponent.CreateDynamicMaterialInstance(MaterialIndex);
		MaterialInstanceDynamic.SetScalarParameterValue(n"ScalarParameterName", 1.0f);
		MaterialInstanceDynamic.SetVectorParameterValue(n"VectorParameterName", FLinearColor(1, 2, 3, 4));
		MaterialInstanceDynamic.SetTextureParameterValue(n"TextureParameterName", MyTexture);
		

		// Alternatively, you can create a new Dynamic Mateiral instance on its own and then assign it to the mesh.
		MaterialInstanceDynamic = Material::CreateDynamicMaterialInstance(this, MaterialInterface);
		MaterialInstanceDynamic.SetScalarParameterValue(n"ScalarParameterName", 1.0f);
		MaterialInstanceDynamic.SetVectorParameterValue(n"VectorParameterName", FLinearColor(1, 2, 3, 4));
		MaterialInstanceDynamic.SetTextureParameterValue(n"TextureParameterName", MyTexture);
		StaticMeshComponent.SetMaterial(MaterialIndex, MaterialInstanceDynamic);


	}
}