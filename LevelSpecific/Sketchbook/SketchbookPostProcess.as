namespace Sketchbook
{
	UFUNCTION(BlueprintPure)
	ASketchbookPostProcess GetSketchbookPostProcess()
	{
		return TListedActors<ASketchbookPostProcess>().Single;
	}
}

UCLASS(Abstract)
class ASketchbookPostProcess : AHazePostProcessVolume
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(EditAnywhere)
	UMaterialInterface PostProcessMaterial;

	UPROPERTY(NotEditable)
	UMaterialInstanceDynamic PostProcessMaterialDynamic;

	UPROPERTY(DefaultComponent)
	UHazeListedActorComponent ListActorComp;

	UPROPERTY(EditAnywhere, Category = "Parameters")
	FLinearColor MioColorDarkCave = FLinearColor(0.58, 0.49, 0.44);

	UPROPERTY(EditAnywhere, Category = "Parameters")
	FLinearColor MioColorDefault = FLinearColor(0.67, 0.57, 0.51);

	bool bIsInDarkCave = false;
	bool bIsBlendingMioColor = false;
	float MioColorAlpha = 0;
	FLinearColor BlendMioColorStart;
	FLinearColor BlendMioColorTarget;

	UPROPERTY(EditAnywhere, Interp, BlueprintSetter = "SetColorizedRadius")
	float ColorizedRadius;

	UFUNCTION(BlueprintOverride)
	void ConstructionScript()
	{
		Super::ConstructionScript();
		Init();

	}

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		Init();

		PostProcessMaterialDynamic.SetVectorParameterValue(n"MioColor", MioColorDefault);
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		if (bIsBlendingMioColor)
		{
			MioColorAlpha = Math::Clamp(MioColorAlpha + (DeltaSeconds / 5.0), 0.0, 1.0);
			FLinearColor NewColor = Math::Lerp(BlendMioColorStart, BlendMioColorTarget, MioColorAlpha);
			PostProcessMaterialDynamic.SetVectorParameterValue(n"MioColor", NewColor);

			if (Math::IsNearlyEqual(MioColorAlpha, 1.0))
			{
				MioColorAlpha = 0;
				bIsBlendingMioColor = false;
			}
		}
	}

	void Init()
	{
		PostProcessMaterialDynamic = Material::CreateDynamicMaterialInstance(this, PostProcessMaterial);

		if (PostProcessMaterialDynamic != nullptr)
		{
			FWeightedBlendable Blendable;
			Blendable.Object = PostProcessMaterialDynamic;
			Blendable.Weight = 1.0;

			Settings.WeightedBlendables.Array.Empty();
			Settings.WeightedBlendables.Array.Add(Blendable);

			Settings.AmbientCubemapIntensity = 0;
		}
	}

	UFUNCTION()
	void SetColorizedOriginPosition(FVector WorldPosition)
	{
		PostProcessMaterialDynamic.SetVectorParameterValue(n"ColorizePosition", FLinearColor(WorldPosition));
	}

	UFUNCTION()
	void SetColorizedSkySphere(float Ratio)
	{
		PostProcessMaterialDynamic.SetScalarParameterValue(n"ColorizedSkyRatio", Ratio);
	}

	UFUNCTION()
	void SetColorizedRadius(float Radius)
	{
		PostProcessMaterialDynamic.SetScalarParameterValue(n"ColorizeRadius", Radius);
	}

	UFUNCTION()
	void SetColorizedHardness(float Ratio)
	{
		PostProcessMaterialDynamic.SetScalarParameterValue(n"ColorizeHardness", Ratio);
	}

	UFUNCTION()
	void SetIs3D(float Is3D)
	{
		PostProcessMaterialDynamic.SetScalarParameterValue(n"Is3D", Is3D);
	}

	UFUNCTION()
	void SetPlayerStencilValue(AHazePlayerCharacter Player, int Value)
	{
		const FName ParameterName = Player == Game::Mio ? n"MioStencil" : n"ZoeStencil";
		PostProcessMaterialDynamic.SetScalarParameterValue(ParameterName, Value);
	}

	UFUNCTION()
	void SetPenShadowStencilValue(int Value)
	{
		PostProcessMaterialDynamic.SetScalarParameterValue(n"PenShadowStencil", Value);
	}

	/** Will blend Zoe towards a even darker color to be able to distinguish between the players */
	UFUNCTION()
	void EnterCave()
	{
		if (bIsInDarkCave)
			return;

		bIsInDarkCave = true;

		MioColorAlpha = 0;
		bIsBlendingMioColor = true;

		BlendMioColorStart = PostProcessMaterialDynamic.GetVectorParameterValue(n"MioColor");
		BlendMioColorTarget = MioColorDarkCave;
	}

	UFUNCTION()
	void ExitCave()
	{
		if (!bIsInDarkCave)
			return;

		bIsInDarkCave = false;

		MioColorAlpha = 0;
		bIsBlendingMioColor = true;

		BlendMioColorStart = PostProcessMaterialDynamic.GetVectorParameterValue(n"MioColor");
		BlendMioColorTarget = MioColorDefault;
	}
};