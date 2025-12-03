UCLASS(HideCategories = "Physics Navigation VirtualTexture StaticMesh Physics Navigation VirtualTexture Cooking Acitvation Actor Tags Debug Rendering Lighting Collision Materials ")
class UDistantLightComponent : UStaticMeshComponent {
	default bCastDynamicShadow = false;
	// Set the default mesh in the child BP
}

UCLASS(Abstract, HideCategories = "StaticMesh Physics Navigation VirtualTexture Cooking Acitvation Actor Tags Debug Rendering Lighting Collision Materials ")
class ADistantLight : AHazeActor {
	UPROPERTY(DefaultComponent, RootComponent, ShowOnActor)
	UDistantLightComponent LightShape;

	// TODO: Some nice looking sprite that makes sense for distant lights,
	UPROPERTY(DefaultComponent)
	UBillboardComponent Billboard;
	default Billboard.bIsEditorOnly = true;
#if EDITOR
	default Billboard.bUseInEditorScaling = true;
#endif

	// Properties for setting the default Distant Light material parameters.
	UPROPERTY(EditAnywhere, Category="Distant Light")
	float Intensity = 1.0;

	UPROPERTY(EditAnywhere, Category="Distant Light")
	FLinearColor Color = FLinearColor(1.0, 1.0, 0.9, 1.0);

	UPROPERTY(EditAnywhere, Category="Distant Light")
	float Size = 0.01;

	UPROPERTY(EditAnywhere, Category="Distant Light")
	bool bPulseEmissive = false;

	// Extra properties for Pulsating materials.
	UPROPERTY(EditAnywhere, Category="Pulse Emissive", Meta=(EditCondition="bPulseEmissive", EditConditionHides))
	float Speed;

	UPROPERTY(EditAnywhere, Category="Pulse Emissive", Meta=(EditCondition="bPulseEmissive", EditConditionHides))
	UTexture2D Texture;

	UPROPERTY(EditAnywhere, Category="Pulse Emissive", Meta=(EditCondition="bPulseEmissive", EditConditionHides))
	float MinBrightness = 0.0;

	UPROPERTY(EditAnywhere, Category="Pulse Emissive", Meta=(EditCondition="bPulseEmissive", EditConditionHides))
	float Time = 0.0;

	UPROPERTY(EditAnywhere, Category="Pulse Emissive", Meta=(EditCondition="bPulseEmissive", EditConditionHides))
	float Scale = 1.0;

	UPROPERTY(EditAnywhere, Category="Pulse Emissive", Meta=(EditCondition="bPulseEmissive", EditConditionHides))
	FLinearColor VertexColorGradientChannel = FLinearColor(0.0, 1.0, 0.0, 0.0);

	UPROPERTY(EditAnywhere, Category="Pulse Emissive", Meta=(EditCondition="bPulseEmissive", EditConditionHides))
	bool bFlipDirection = false;

	UPROPERTY(EditAnywhere, Category="Pulse Emissive", Meta=(EditCondition="bPulseEmissive", EditConditionHides))
	int PropLineIndex = 0;

	// Private properties, to see in child material, show inherited variables
	UPROPERTY()
	UMaterial DistantLightMaterial;

	UPROPERTY()
	UMaterialInstance DistantLightPulsatingMaterialInstance;

	UPROPERTY()
	UMaterialInstanceDynamic DynamicMaterialInstance;

	UFUNCTION(BlueprintOverride)
    void ConstructionScript()
	{
		LightShape.SetBoundsScale(9999.99);

		if (bPulseEmissive)
			DynamicMaterialInstance = LightShape.CreateDynamicMaterialInstance(0, DistantLightPulsatingMaterialInstance);
		else
			DynamicMaterialInstance = LightShape.CreateDynamicMaterialInstance(0, DistantLightMaterial);

		DynamicMaterialInstance.SetScalarParameterValue(n"Intensity", Intensity);
		DynamicMaterialInstance.SetVectorParameterValue(n"Color", Color);
		DynamicMaterialInstance.SetScalarParameterValue(n"Size", Size);
		
		if (bPulseEmissive) {
			DynamicMaterialInstance.SetScalarParameterValue(n"PulseEmissive_Speed", Speed);
			DynamicMaterialInstance.SetTextureParameterValue(n"PulseEmissive_Texture", Texture);
			DynamicMaterialInstance.SetScalarParameterValue(n"PulseEmissive_MinBrightness", MinBrightness);
			DynamicMaterialInstance.SetScalarParameterValue(n"PulseEmissive_Time", Time);
			DynamicMaterialInstance.SetScalarParameterValue(n"PulseEmissive_Scale", Scale);
			DynamicMaterialInstance.SetVectorParameterValue(n"PulseEmissive_VertexColorGradientChannel", VertexColorGradientChannel);
			DynamicMaterialInstance.SetScalarParameterValue(n"PulseEmissive_FlipDirection", (bFlipDirection) ? 1.0 : 0.0);
			DynamicMaterialInstance.SetScalarParameterValue(n"PulseEmissive_PropLineIndex", Math::RoundToFloat(PropLineIndex));
		}
	}
}