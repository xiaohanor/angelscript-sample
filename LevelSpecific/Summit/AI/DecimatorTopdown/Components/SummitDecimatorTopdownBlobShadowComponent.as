class USummitDecimatorTopdownBlobShadowComponent : UActorComponent
{
	UPROPERTY()
	UMaterialInterface ShadowDecalMaterial;
	UPROPERTY()
	UCurveFloat OpacityCurve;
	UPROPERTY()
	UCurveFloat SizeCurve;
	
	UPROPERTY()
	float SizeFactor = 0.40;
	

	UMaterialInstanceDynamic DynamicMaterial;
}