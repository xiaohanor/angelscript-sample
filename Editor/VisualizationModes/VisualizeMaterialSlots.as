class UVisualizeMaterialSlots
{
	UFUNCTION()
	bool GetVisualizeColor(UObject Object, FLinearColor& OutColor) const
	{
		UStaticMeshComponent StaticMeshComponent = Cast<UStaticMeshComponent>(Object);
		if (StaticMeshComponent == nullptr)
			return false;
		
		int32 MaterialSlots = StaticMeshComponent.Materials.Num();

		switch (MaterialSlots) {
			case 0:
				OutColor = FLinearColor(0, 0, 0);
				break;
			case 1:
				OutColor = FLinearColor(0.04, 0.04, 0.28);
				break;
			case 2:
				OutColor = FLinearColor(0.1, 0.1, 1.0, 1.0);
				break;
			case 3:
				OutColor = FLinearColor(0.11, 0.60, 0.40);
				break;
			case 4:
				OutColor = FLinearColor(0.07, 0.89, 0.17);
				break;
			case 5:
				OutColor = FLinearColor(0.67, 0.71, 0.00);
				break;
			case 6:
				OutColor = FLinearColor(0.89, 0.55, 0.07);
				break;
			case 7:
				OutColor = FLinearColor(0.89, 0.07, 0.07);
				break;
			case 8:
				OutColor = FLinearColor(0.57, 0.09, 0.49);
				break;
			case 9:
				OutColor = FLinearColor(0.77, 0.49, 0.85);
				break;
			default:
				OutColor = FLinearColor(1, 1, 1);
		}

		return true;
	}
}