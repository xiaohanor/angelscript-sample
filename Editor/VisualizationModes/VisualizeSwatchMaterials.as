const FLinearColor Color(1.0, 0.0, 1.0);

class UVisualizeSwatchMaterials
{
	UFUNCTION()
	bool GetVisualizeColor(UObject Object, FLinearColor& OutColor) const
	{
		UStaticMeshComponent StaticMeshComponent = Cast<UStaticMeshComponent>(Object);
		if (StaticMeshComponent != nullptr)
		{
			int SwatchCount = 0;
			for (auto Material : StaticMeshComponent.Materials ) {
				FName MaterialName = Material.GetName();
				FString MaterialString = MaterialName.ToString();
				bool IsSwatch = MaterialString.ToLower().Contains("swatch");
				if (IsSwatch) {
					SwatchCount += 1;
				}
			}

			if (SwatchCount > 0) {
				OutColor = Color;
				return true;
			}
		}
		
		return false;
	}
}