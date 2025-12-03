

class ULensFlareComponent : UStaticMeshComponent
{
	default SetCollisionEnabled(ECollisionEnabled::NoCollision);
	default Mobility = EComponentMobility::Movable;

	UPROPERTY(EditAnywhere)
    bool Omnidirectional = true;

	UPROPERTY(EditAnywhere)
    float FadeDistanceMin = 100.0;

	UPROPERTY(EditAnywhere)
    float FadeDistanceMax = 10000.0;

    UPROPERTY(EditAnywhere)
    UTexture2D Texture;

    UPROPERTY()
    UTexture2D HoopTexture;

    UPROPERTY(EditAnywhere)
    FLinearColor Tint = FLinearColor(1, 1, 1, 1);
	
    UPROPERTY(EditAnywhere)
    float HoopOpacity = 0.0;

	UPROPERTY(EditAnywhere)
    bool bDebug = false;
    UPROPERTY()
	UStaticMesh Mesh;

    UPROPERTY()
	UMaterialInterface Material;
    UPROPERTY()
	UMaterialInstanceDynamic MaterialDynamic;

	UPROPERTY(EditAnywhere, BlueprintReadOnly, Meta = (MakeEditWidget))
	FVector VisibilitySampleLocation;

	UPROPERTY(EditAnywhere, BlueprintReadOnly, Meta = (MakeEditWidget))
	float VisibilitySampleRadius = 10.0;

#if EDITOR
	UFUNCTION(BlueprintOverride)
	void OnComponentModifiedInEditor()
	{
		LoadAssets();
	}

	UFUNCTION(BlueprintOverride)
	private void OnActorOwnerModifiedInEditor()
	{
		LoadAssets();
		InitDynamicMaterial();
	}

	UFUNCTION(BlueprintOverride)
	void OnComponentCompiledInBlueprint()
	{
		LoadAssets();
	}

	void LoadAssets()
	{
		Mesh = Cast<UStaticMesh>(LoadObject(nullptr, "/Game/Environment/Blueprints/LensFlare/Flare.Flare"));
		Material = Cast<UMaterialInterface>(LoadObject(nullptr, "/Game/MasterMaterials/Generated/Effect/Effect_LensFlareComponent.Effect_LensFlareComponent"));
		HoopTexture = Cast<UTexture2D>(LoadObject(nullptr ,"/Game/Environment/Blueprints/LensFlare/Flare_Hoop.Flare_Hoop"));
		if (Texture == nullptr)
			Texture = Cast<UTexture2D>(LoadObject(nullptr, "/Game/Environment/Blueprints/LensFlare/Flare_Simple.Flare_Simple"));

		SetStaticMesh(Mesh);
		SetMaterial(0, Material);
	}
#endif

    UFUNCTION()
	void SetTintValue(FLinearColor NewTint)
	{
		Tint = NewTint;
		MaterialDynamic.SetVectorParameterValue(n"Tint", Tint);
	}

	UFUNCTION()
	void InitDynamicMaterial()
	{
		MaterialDynamic = CreateDynamicMaterialInstance(0, Material);
		if (MaterialDynamic != nullptr)
		{
			float Scale = GetWorldScale().X;
			
			MaterialDynamic.SetTextureParameterValue(n"TexFlare", Texture);
			MaterialDynamic.SetTextureParameterValue(n"TexHoop", HoopTexture);
			MaterialDynamic.SetScalarParameterValue(n"Scale", Scale);
			MaterialDynamic.SetScalarParameterValue(n"HazeToggle_Omnidirectional", Omnidirectional ? 1 : 0);
			MaterialDynamic.SetScalarParameterValue(n"HazeToggle_IsCombined", 1);
			MaterialDynamic.SetScalarParameterValue(n"HazeToggle_HoopEnabled", HoopOpacity > 0.0 ? 1 : 0);
			MaterialDynamic.SetScalarParameterValue(n"HoopOpacity", HoopOpacity);
			MaterialDynamic.SetVectorParameterValue(n"Tint", Tint);

			MaterialDynamic.SetVectorParameterValue(n"VisibilitySampleLocation", FLinearColor(VisibilitySampleLocation));
			MaterialDynamic.SetScalarParameterValue(n"VisibilitySampleRadius", VisibilitySampleRadius);
			//MaterialDynamic.SetVectorParameterValue(n"BlueprintForward", FLinearColor(ForwardVector.X, ForwardVector.Y, ForwardVector.Z, 0));
			//SetWorldRotation(FRotator(0, 0, 0));

			MaterialDynamic.SetScalarParameterValue(n"FadeDistanceMax", FadeDistanceMax);
			MaterialDynamic.SetScalarParameterValue(n"FadeDistanceMin", FadeDistanceMin);
			MaterialDynamic.SetScalarParameterValue(n"HazeToggle_Debug", bDebug ? 1 : 0);
			//MaterialDynamic.SetScalarParameterValue(n"MaxDrawDistanceFadeRange", FadeDist);
		}
	}

    UFUNCTION(BlueprintOverride)
	void BeginPlay()
    {
		InitDynamicMaterial();
		if (MaterialDynamic == nullptr)
			devError("Lensflare materials are configured incorrectly");
    }
	
    UFUNCTION()
    void ConstructionScript_Hack()
    {
		#if EDITOR
		LoadAssets();
		InitDynamicMaterial();
		#endif
    }
}