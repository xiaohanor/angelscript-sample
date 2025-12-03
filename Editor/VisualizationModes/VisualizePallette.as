const FLinearColor UniformScaledColor(0.1, 1.0, 0.1);
const FLinearColor NonUniformScaledColor(1.0, 0.1, 0.1);

class UVisualizePalette
{
	UFUNCTION()
	bool GetVisualizeColor(UObject Object, FLinearColor& OutColor) const
	{
		// Only affect staticmeshcomps
		UStaticMeshComponent StaticMeshComponent = Cast<UStaticMeshComponent>(Object);
		if (StaticMeshComponent == nullptr)
			return false;
		
		if(StaticMeshComponent.Materials.Num() == 0)
			return false;
		
		if(StaticMeshComponent.Materials[0] == nullptr)
			return false;

		// Skip hazespheres and glass.
		EBlendMode BlendMode = StaticMeshComponent.Materials[0].BaseMaterial.BlendMode;
		if(BlendMode != EBlendMode::BLEND_Opaque && BlendMode != EBlendMode::BLEND_Masked)
			return false;

		float RandomNumber1 = Math::Frac(StaticMeshComponent.StaticMesh.GetName().GetHash() / 100.0f) + 0.5;
		float RandomNumber2 = Math::Frac(StaticMeshComponent.StaticMesh.GetName().GetHash() / 1000.0f) + 0.5;
		float RandomNumber3 = Math::Frac(StaticMeshComponent.StaticMesh.GetName().GetHash() / 10000.0f) + 0.5;

		OutColor = FLinearColor(RandomNumber1, RandomNumber2, RandomNumber3);
		return true;
	}
}