UCLASS(Abstract)
class AIslandRedBlueImpactOverchargeResponseDisplay : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root, ShowOnActor)
	UIslandRedBlueImpactOverchargeResponseDisplayComponent Display;
}

class UIslandRedBlueImpactOverchargeResponseDisplayComponent : UStaticMeshComponent
{
	default CollisionProfileName = n"NoCollision";

	UPROPERTY(EditAnywhere)
	FLinearColor BlueColor = FLinearColor(1.00, 0.294169, 0.00);
	// FLinearColor BlueColor = FLinearColor(0.00, 0.07, 1.00);

	UPROPERTY(EditAnywhere)
	FLinearColor RedColor = FLinearColor(1.00, 0.294169, 0.00);
	// FLinearColor RedColor = FLinearColor(1.00, 0.00, 0.00);

	UPROPERTY(EditAnywhere)
	FLinearColor BothColor = FLinearColor(1.00, 0.294169, 0.00);

	/* Which material slot the dynamic material is in */
	UPROPERTY(EditAnywhere)
	int MaterialSlotIndex = 0;

	UPROPERTY(EditAnywhere)
	UMaterialInterface CompletedMaterial;

	private UMaterialInstanceDynamic Internal_DynamicMaterial;
	private bool bHasInit = false;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		Init();
	}

	private void Init()
	{
		if(bHasInit)
			return;

		DynamicMaterial.SetScalarParameterValue(n"FillPercentage", 0.0);
		bHasInit = true;
	}

	void SetColor(EIslandRedBlueShieldType ShieldType)
	{
		if(ShieldType == EIslandRedBlueShieldType::Blue)
			DynamicMaterial.SetVectorParameterValue(n"FillColor", BlueColor);
		else if(ShieldType == EIslandRedBlueShieldType::Red)
			DynamicMaterial.SetVectorParameterValue(n"FillColor", RedColor);
		else if(ShieldType == EIslandRedBlueShieldType::Both)
			DynamicMaterial.SetVectorParameterValue(n"FillColor", BothColor);
	}

	void SetColor(EIslandRedBlueOverchargeColor OverchargeColor)
	{
		if(OverchargeColor == EIslandRedBlueOverchargeColor::Blue)
			DynamicMaterial.SetVectorParameterValue(n"FillColor", BlueColor);
		else if(OverchargeColor == EIslandRedBlueOverchargeColor::Red)
			DynamicMaterial.SetVectorParameterValue(n"FillColor", RedColor);
	}

	void SetFillPercentage(float Alpha)
	{
		Init();
		DynamicMaterial.SetScalarParameterValue(n"FillPercentage", Alpha);
	}

	void SetCompleted()
	{
		DynamicMaterial.SetScalarParameterValue(n"FillPercentage", 1.0);
		if(CompletedMaterial != nullptr)
			SetMaterial(MaterialSlotIndex, CompletedMaterial);
	}

	UMaterialInstanceDynamic GetDynamicMaterial() property
	{
		if(Internal_DynamicMaterial == nullptr)
			Internal_DynamicMaterial = CreateDynamicMaterialInstance(MaterialSlotIndex);

		return Internal_DynamicMaterial;
	}
}