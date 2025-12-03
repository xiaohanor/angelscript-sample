class UBombTossPlatformLightStrip : UStaticMeshComponent
{
	UPROPERTY(EditDefaultsOnly)
	EBombTossPlatformLightPlacement LightPlacement;
	TArray<FLinearColor> Colors;
	UPROPERTY(EditDefaultsOnly)
	UMaterialInterface SourceMaterial;

	UMaterialInstanceDynamic DynamicMaterialInstance;

	void SetPreviewLightFormation(EBombTossPlatformLightFormation Formation, EBombTossPlatformLightColor Color)
	{
		if (Colors.Num() == 0)
		{
			Colors.SetNum(EBombTossPlatformLightColor::Num);
			Colors[EBombTossPlatformLightColor::None] = FLinearColor(0, 0, 0);
			Colors[EBombTossPlatformLightColor::Green] = FLinearColor(0, 60, 0);
			Colors[EBombTossPlatformLightColor::Red] = FLinearColor(60, 0, 0);
			Colors[EBombTossPlatformLightColor::White] = FLinearColor(20, 20, 20);
		}
		if (DynamicMaterialInstance == nullptr)
			DynamicMaterialInstance = CreateDynamicMaterialInstance(0, SourceMaterial);

		int LightPlacementBitMask = 1 << uint(LightPlacement);
		int FormationValue = int(Formation);

		if (LightPlacementBitMask & FormationValue > 0)
		{
			SetVisibility(true);
			DynamicMaterialInstance.SetVectorParameterValue(n"EmissiveColor", Colors[Color]);
		}
		else
		{
			SetVisibility(false);
		}
	}

	void SetLightLinearColor(FLinearColor Color)
	{
		if (DynamicMaterialInstance == nullptr)
			DynamicMaterialInstance = CreateDynamicMaterialInstance(0, SourceMaterial);

		DynamicMaterialInstance.SetVectorParameterValue(n"EmissiveColor", Color);
	}
}