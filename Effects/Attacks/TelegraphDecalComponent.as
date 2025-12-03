enum ETelegraphDecalType
{
	Fantasy,
	Scifi,
}

UCLASS(HideCategories = "Decal Debug Activation Cooking Tags LOD Navigation Internal")
class UTelegraphDecalComponent : UDecalComponent
{
	default bTickInEditor = true;

	access EditOnly = private, * (readonly, editdefaults);

	UPROPERTY(EditAnywhere, Category = "Telegraph")
	access:EditOnly ETelegraphDecalType Type = ETelegraphDecalType::Fantasy;
	UPROPERTY(EditAnywhere, Category = "Telegraph")
	access:EditOnly float Radius = 100.0;
	UPROPERTY(EditAnywhere, Category = "Telegraph")
	access:EditOnly bool bAutoShow = true;
	UPROPERTY(EditAnywhere, Category = "Telegraph")
	access:EditOnly float ShowDuration = 0.5;

	UPROPERTY(EditAnywhere, Category = "Telegraph", AdvancedDisplay)
	access:EditOnly float DisplayHeight = 50.0;

	UPROPERTY(VisibleAnywhere, Category = "Internal")
	private UMaterialInterface ScifiMaterial;
	UPROPERTY(VisibleAnywhere, Category = "Internal")
	private UMaterialInterface FantasyMaterial;

	UPROPERTY(EditAnywhere, Category = "Visuals")
	access:EditOnly bool bOverrideColor = false;

	UPROPERTY(EditAnywhere, Category = "Visuals", Meta = (EditCondition = "Type == ETelegraphDecalType::Fantasy && bOverrideColor", EditConditionHides))
	access:EditOnly FLinearColor PrimaryColor_Fantasy = FLinearColor(50.0, 1.28107, 0.0, 1.0);
	// UPROPERTY(EditAnywhere, Category = "Visuals", Meta = (EditCondition = "Type == ETelegraphDecalType::Fantasy && bOverrideColor", EditConditionHides))
	// access:EditOnly FLinearColor SecondaryColor_Fantasy = FLinearColor(1.0, 0.0, 0.18981, 1.0);

	UPROPERTY(EditAnywhere, Category = "Visuals", Meta = (EditCondition = "Type == ETelegraphDecalType::Scifi && bOverrideColor", EditConditionHides))
	access:EditOnly FLinearColor PrimaryColor_Scifi = FLinearColor(10.0, 0.0, 0.075788, 1.0);
	// UPROPERTY(EditAnywhere, Category = "Visuals", Meta = (EditCondition = "Type == ETelegraphDecalType::Scifi && bOverrideColor", EditConditionHides))
	// access:EditOnly FLinearColor SecondaryColor_Scifi = FLinearColor(1.0, 0.050657, 0.0, 1.0);

	UPROPERTY(EditAnywhere, Category = "Visuals")
	access:EditOnly bool bOverridePulseAmount = false;
	UPROPERTY(EditAnywhere, Category = "Visuals", Meta = (EditCondition = "bOverridePulseAmount", EditConditionHides))
	access:EditOnly float PulseAmount = 1.0;

	UPROPERTY(EditAnywhere, Category = "Visuals")
	access:EditOnly bool bOverrideEdgeGlow = false;
	UPROPERTY(EditAnywhere, Category = "Visuals", Meta = (EditCondition = "bOverrideEdgeGlow", EditConditionHides))
	access:EditOnly float EdgeGlow = 1.0;

	UPROPERTY(EditAnywhere, Category = "Visuals", Meta = (EditCondition = "Type == ETelegraphDecalType::Fantasy", EditConditionHides))
	access:EditOnly float RotationRate = 1.0;

	private float Size = 0.0;
	private bool bShow = false;
	private UMaterialInstanceDynamic DynamicMaterial;

	UFUNCTION()
	void ShowTelegraph()
	{
		bShow = true;
	}

	UFUNCTION()
	void HideTelegraph()
	{
		bShow = false;
	}

	void SetRadius(float NewRadius)
	{
		Radius = NewRadius;
		UpdateSettings();
	}

	void SetTelegraphType(ETelegraphDecalType NewType)
	{
		Type = NewType;
		UpdateSettings();
	}

#if EDITOR
	UFUNCTION(BlueprintOverride)
	private void OnComponentCompiledInBlueprint()
	{
		SetDecalMaterial(nullptr);
		UpdateAssetReferences();
	}

	UFUNCTION(BlueprintOverride)
	private void OnComponentModifiedInEditor()
	{
		if (AttachParent != nullptr)
			SetRelativeRotation(FRotator(90, 0, 0));
		UpdateAssetReferences();
		UpdateSettings();
	}

	UFUNCTION(BlueprintOverride)
	private void OnActorOwnerModifiedInEditor()
	{
		if (AttachParent != nullptr)
			SetRelativeRotation(FRotator(90, 0, 0));
		UpdateAssetReferences();
		UpdateSettings();
	}

	private void UpdateAssetReferences()
	{
		ScifiMaterial = Cast<UMaterialInterface>(LoadObject(nullptr, "/Game/Effects/Materials/MI_ImpactTelegraphDecalSciFi_01.MI_ImpactTelegraphDecalSciFi_01"));
		FantasyMaterial = Cast<UMaterialInterface>(LoadObject(nullptr, "/Game/Effects/Materials/MI_ImpactTelegraphDecalFantasy_01.MI_ImpactTelegraphDecalFantasy_01"));
	}
#endif

	private void UpdateSettings()
	{
		if (Type == ETelegraphDecalType::Scifi)
		{
			SetDecalMaterial(ScifiMaterial);
			if (bOverrideColor || bOverridePulseAmount || bOverrideEdgeGlow)
			{
				DynamicMaterial = CreateDynamicMaterialInstance();
				if (DynamicMaterial != nullptr)
				{
					if (bOverrideColor)
					{
						DynamicMaterial.SetVectorParameterValue(n"ColorB", PrimaryColor_Scifi);
						// DynamicMaterial.SetVectorParameterValue(n"ColorA", SecondaryColor_Scifi);
					}

					if (bOverridePulseAmount)
					{
						DynamicMaterial.SetScalarParameterValue(n"PulseAmount", PulseAmount);
					}

					if (bOverrideEdgeGlow)
					{
						DynamicMaterial.SetScalarParameterValue(n"EdgeGlow", EdgeGlow);
					}
				}
			}
		}
		else
		{
			SetDecalMaterial(FantasyMaterial);
			if (bOverrideColor || bOverridePulseAmount || bOverrideEdgeGlow)
			{
				DynamicMaterial = CreateDynamicMaterialInstance();
				if (DynamicMaterial != nullptr)
				{
					if (bOverrideColor)
					{
						DynamicMaterial.SetVectorParameterValue(n"ColorB", PrimaryColor_Fantasy);
						// DynamicMaterial.SetVectorParameterValue(n"ColorA", SecondaryColor_Fantasy);
					}

					if (bOverridePulseAmount)
					{
						DynamicMaterial.SetScalarParameterValue(n"PulseAmount", PulseAmount);
					}

					if (bOverrideEdgeGlow)
					{
						DynamicMaterial.SetScalarParameterValue(n"EdgeGlow", EdgeGlow);
					}
				}
			}
		}

		SetDecalSize(FVector(DisplayHeight, Radius*1.15, Radius*1.15));
	}

	UFUNCTION(BlueprintOverride)
	private void BeginPlay()
	{
		SetHiddenInGame(true);
		UpdateSettings();

		if (bAutoShow)
			ShowTelegraph();
	}

	UFUNCTION(BlueprintOverride)
	private void Tick(float DeltaSeconds)
	{
		if (Type == ETelegraphDecalType::Fantasy && !IsHiddenInGame())
			SetRelativeRotation(FRotator(90, -250 * Time::GameTimeSeconds * RotationRate, 0.0));

		bool bUpdateShow = true;

#if EDITOR
		bUpdateShow = GetWorld() != nullptr && GetWorld().IsGameWorld();
#endif

		if (bUpdateShow)
		{
			if (bShow)
			{
				if (Size < 1.0)
				{
					if (ShowDuration > 0)
						Size = Math::FInterpConstantTo(Size, 1.0, DeltaSeconds, 1.0 / ShowDuration);
					else
						Size = 1.0;
					SetRelativeScale3D(FVector(Size, Size, Size));
					SetHiddenInGame(false);
				}
			}
			else
			{
				Size = Math::FInterpConstantTo(Size, 0.0, DeltaSeconds, 6.0);
				if (Size > 0.0)
					SetRelativeScale3D(FVector(Size, Size, Size));
				else
					SetHiddenInGame(true);
			}
		}
	}
}
