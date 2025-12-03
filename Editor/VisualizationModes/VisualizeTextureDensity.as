class UVisualizeTextureDensity
{
	UFUNCTION()
	int GetMaterialVisualizationIndex(UObject Object)
	{
		// Only affect staticmeshcomps
		UStaticMeshComponent StaticMeshComponent = Cast<UStaticMeshComponent>(Object);
		if (StaticMeshComponent == nullptr)
			return 0;
		
		if(StaticMeshComponent.Materials.Num() == 0)
			return 0;
		
		if(StaticMeshComponent.Materials[0] == nullptr)
			return 0;

		// Skip hazespheres and glass.
		EBlendMode BlendMode = StaticMeshComponent.Materials[0].BaseMaterial.BlendMode;
		if(BlendMode != EBlendMode::BLEND_Opaque && BlendMode != EBlendMode::BLEND_Masked)
			return 0;
		
		if(StaticMeshComponent.Materials[0].BaseMaterial.Name.ToString().ToLower().StartsWith("swatch"))
			return 0;
		
		return 1;
	}
}