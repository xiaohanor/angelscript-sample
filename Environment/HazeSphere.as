
enum EFogVolume
{
    Sphere,
	HalfSphere,
    Box,
    Mesh,
};

enum EColorType
{
    Color,
    Gradient,
    Temperature,
};

enum EScaleType
{
    Free,
    Uniform,
    Locked,
};

enum ERotationType
{
    Free,
    Uniform,
    Locked,
};

struct FHazeSphereData
{
    UStaticMesh Mesh;
    EScaleType ScaleType;
    ERotationType RotationType;
    // Scale factor is the length longest line through the object.
    float ScaleFactor;
}

struct FHazeSphereBlendFloat
{
	FHazeSphereBlendFloat(float InStart, float InTarget)
	{
		this.Start = InStart;
		this.Target = InTarget;
	}
	float Blend(float T)
	{
		return Math::Lerp(Start, Target, T);
	}
	float Start;
	float Target;
}
struct FHazeSphereBlendColor
{
	FHazeSphereBlendColor(FLinearColor InStart, FLinearColor InTarget)
	{
		this.Start = InStart;
		this.Target = InTarget;
	}
	FLinearColor Blend(float T)
	{
		return FLinearColor(Math::Lerp(Start.R, Target.R, T),
							Math::Lerp(Start.G, Target.G, T),
							Math::Lerp(Start.B, Target.B, T), 
							Math::Lerp(Start.A, Target.A, T));
	}
	FLinearColor Start;
	FLinearColor Target;
}

const FConsoleVariable CVar_HazeSphereTest("Haze.ToggleHazeSphereTest", 0);

// UCLASS(hidecategories="StaticMesh Materials Physics Collision Lighting Physics Activation Cooking Replication Input Actor HLOD Mobile AssetUserData Tags VirtualTexture Navigation", NotPlaceable)
class UHazeSphereComponent : UHazeSphereComponentBase
{
    default CollisionProfileName = n"NoCollision";
	default CastShadow = false;
	default PrimaryComponentTick.bStartWithTickEnabled = false;
	default bAffectDistanceFieldLighting = false;
	default bCanEverAffectNavigation = false;
	default SetBoundsScale(1.5f);

    UPROPERTY(EditAnywhere)
    EFogVolume Type = EFogVolume::Sphere;
	
	UPROPERTY(EditAnywhere)
    float TestOffset = 0.0;

	UPROPERTY(EditAnywhere)
    float Opacity = 1.0;
	FHazeSphereBlendFloat BlendOpacity;
    
    UPROPERTY(EditAnywhere)
    float Softness = 1.0;
	FHazeSphereBlendFloat BlendSoftness;
    
    UPROPERTY(EditAnywhere)
    EColorType ColorType = EColorType::Color;
    
    UPROPERTY(EditAnywhere)
    bool bLinear = false;
	
    UPROPERTY(EditAnywhere)
    bool bWaterGlitchFix = false;

    UPROPERTY(EditAnywhere, Meta = (EditCondition="Type == EFogVolume::Mesh", EditConditionHides))
    UStaticMesh Mesh;
	
    UPROPERTY(EditAnywhere, Meta = (EditCondition="ColorType != EColorType::Temperature", EditConditionHides))
    FLinearColor ColorA = FLinearColor(0.428691, 0.502887, 0.545725, 1.0);
	FHazeSphereBlendColor BlendColorA;

    UPROPERTY(EditAnywhere, Meta = (EditCondition="ColorType == EColorType::Gradient", EditConditionHides))
    FLinearColor ColorB = FLinearColor(0.545725, 0.502887, 0.428691, 1.0);
	FHazeSphereBlendColor BlendColorB;

    UPROPERTY(EditAnywhere, Meta = (EditCondition="ColorType == EColorType::Temperature", EditConditionHides))
    float MinTemperature = 0.0;
	FHazeSphereBlendFloat BlendMinTemperature;

    UPROPERTY(EditAnywhere, Meta = (EditCondition="ColorType == EColorType::Temperature", EditConditionHides))
    float MaxTemperature = 5000.0;
	FHazeSphereBlendFloat BlendMaxTemperature;

    UPROPERTY(EditAnywhere, Meta = (EditCondition="ColorType != EColorType::Color", EditConditionHides))
    float Contrast = 1.0;
	FHazeSphereBlendFloat BlendContrast;
	
    UPROPERTY(EditAnywhere, Meta = (EditCondition="ColorType != EColorType::Color", EditConditionHides))
    float Offset = 0.75;
	FHazeSphereBlendFloat BlendOffset;

    UPROPERTY(EditAnywhere)
    bool ApplyFog = false;

	// Only show this haze sphere in the background, it is not visible if the camera is inside it
    UPROPERTY(EditAnywhere)
    bool bBackgroundOnly = false;

	// Never reduce shading rate for this haze sphere anywhere
    UPROPERTY(EditAnywhere, AdvancedDisplay)
    bool bNeverReduceShadingRate = false;

	// Allow reducing the shading rate for the haze sphere even if the players are inside it
    UPROPERTY(EditAnywhere, AdvancedDisplay, Meta = (EditCondition = "!bNeverReduceShadingRate", EditConditionHides))
    bool bAllowReducedShadingRateWhenInside = false;

	private float CurrentLerpTime = 0;
	private float TotalLerpTime = 0;

    UPROPERTY(EditDefaultsOnly, Category = "Haze Materials", AdvancedDisplay)
    UMaterialInterface HazeSphereMaterial;
    UPROPERTY(EditDefaultsOnly, Category = "Haze Materials", AdvancedDisplay)
    UMaterialInterface HazeSphereMaterial_Inside_Coarse;
    UPROPERTY(EditDefaultsOnly, Category = "Haze Materials", AdvancedDisplay)
    UMaterialInterface HazeSphereMaterial_HalfSphere;
    UPROPERTY(EditDefaultsOnly, Category = "Haze Materials", AdvancedDisplay)
    UMaterialInterface HazeSphereMaterial_Fog;
    UPROPERTY(EditDefaultsOnly, Category = "Haze Materials", AdvancedDisplay)
    UMaterialInterface HazeSphereMaterial_Distant;
    UPROPERTY(EditDefaultsOnly, Category = "Haze Materials", AdvancedDisplay)
    UMaterialInterface HazeSphereMaterial_Fog_Distant;
    UPROPERTY(EditDefaultsOnly, Category = "Haze Materials", AdvancedDisplay)
    UMaterialInterface HazeSphereMaterial_Distant_1x1;
    UPROPERTY(EditDefaultsOnly, Category = "Haze Materials", AdvancedDisplay)
    UMaterialInterface HazeSphereMaterial_Fog_Distant_1x1;
	
    UPROPERTY(EditDefaultsOnly, Category = "Haze Materials", AdvancedDisplay)
    UMaterialInterface HazeSphereMaterial_Advanced;
    UPROPERTY(EditDefaultsOnly, Category = "Haze Materials", AdvancedDisplay)
    UMaterialInterface HazeSphereMaterial_Advanced_Fog;
    UPROPERTY(EditDefaultsOnly, Category = "Haze Materials", AdvancedDisplay)
    UMaterialInterface HazeSphereMaterial_Advanced_Distant;
    UPROPERTY(EditDefaultsOnly, Category = "Haze Materials", AdvancedDisplay)
    UMaterialInterface HazeSphereMaterial_Advanced_Fog_Distant;
    UPROPERTY(EditDefaultsOnly, Category = "Haze Materials", AdvancedDisplay)
    UMaterialInterface HazeSphereMaterial_Advanced_Distant_1x1;
    UPROPERTY(EditDefaultsOnly, Category = "Haze Materials", AdvancedDisplay)
    UMaterialInterface HazeSphereMaterial_Advanced_Fog_Distant_1x1;

    UPROPERTY(EditDefaultsOnly, Category = "Haze Materials", AdvancedDisplay)
    UMaterialInterface HazeMeshMaterialPass0;
    UPROPERTY(EditDefaultsOnly, Category = "Haze Materials", AdvancedDisplay)
    UMaterialInterface HazeMeshMaterialPass1;
    UPROPERTY(EditDefaultsOnly, Category = "Haze Materials", AdvancedDisplay)
    UMaterialInterface HazeMeshMaterialPass0_Fog;
    UPROPERTY(EditDefaultsOnly, Category = "Haze Materials", AdvancedDisplay)
    UMaterialInterface HazeMeshMaterialPass1_Fog;

    UPROPERTY()
    UStaticMesh CubeMesh;

    UPROPERTY(EditAnywhere)
    UStaticMesh SphereMesh;

    UPROPERTY(NotEditable)
	FHazeSphereData Data;

#if EDITOR
	UFUNCTION(BlueprintOverride)
	void OnComponentModifiedInEditor()
	{
		Editor_LoadHazeSphereMaterials();
		ApplyMeshAndMaterial();
	}

	UFUNCTION(BlueprintOverride)
	void OnActorOwnerModifiedInEditor()
	{
		UHazeSphereEditorSubsystem::Get().bDirtyOverlappingHazeSpheres = true;
	}

	UFUNCTION(BlueprintOverride)
	void OnComponentCompiledInBlueprint()
	{
		Editor_LoadHazeSphereMaterials();
		ApplyMeshAndMaterial();
	}

	void Editor_LoadHazeSphereMaterials()
	{
		if (Editor::IsPlaying())
			return;

		HazeSphereMaterial			 			 		= Cast<UMaterialInterface>(LoadObject(nullptr, "/Game/MasterMaterials/Generated/Effect/Effect_HazeSphere.Effect_HazeSphere"));
		HazeSphereMaterial_Inside_Coarse			 	= Cast<UMaterialInterface>(LoadObject(nullptr, "/Game/MasterMaterials/Generated/Effect/Effect_HazeSphere_Inside_Coarse.Effect_HazeSphere_Inside_Coarse"));
		HazeSphereMaterial_HalfSphere			 		= Cast<UMaterialInterface>(LoadObject(nullptr, "/Game/MasterMaterials/Generated/Effect/Effect_HazeSphere_HalfSphere.Effect_HazeSphere_HalfSphere"));
		HazeSphereMaterial_Fog			 		 		= Cast<UMaterialInterface>(LoadObject(nullptr, "/Game/MasterMaterials/Generated/Effect/Effect_HazeSphere_Fog.Effect_HazeSphere_Fog"));
		HazeSphereMaterial_Distant			 	 		= Cast<UMaterialInterface>(LoadObject(nullptr, "/Game/MasterMaterials/Generated/Effect/Effect_HazeSphere_Distant.Effect_HazeSphere_Distant"));
		HazeSphereMaterial_Fog_Distant			 		= Cast<UMaterialInterface>(LoadObject(nullptr, "/Game/MasterMaterials/Generated/Effect/Effect_HazeSphere_Fog_Distant.Effect_HazeSphere_Fog_Distant"));
		HazeSphereMaterial_Distant_1x1		 			= Cast<UMaterialInterface>(LoadObject(nullptr, "/Game/MasterMaterials/Generated/Effect/Effect_HazeSphere_Distant_1x1.Effect_HazeSphere_Distant_1x1"));
		HazeSphereMaterial_Fog_Distant_1x1	 			= Cast<UMaterialInterface>(LoadObject(nullptr, "/Game/MasterMaterials/Generated/Effect/Effect_HazeSphere_Fog_Distant_1x1.Effect_HazeSphere_Fog_Distant_1x1"));
		HazeSphereMaterial_Advanced			 	 		= Cast<UMaterialInterface>(LoadObject(nullptr, "/Game/MasterMaterials/Generated/Effect/Effect_HazeSphere_Advanced.Effect_HazeSphere_Advanced"));
		HazeSphereMaterial_Advanced_Fog			 		= Cast<UMaterialInterface>(LoadObject(nullptr, "/Game/MasterMaterials/Generated/Effect/Effect_HazeSphere_Advanced_Fog.Effect_HazeSphere_Advanced_Fog"));
		HazeSphereMaterial_Advanced_Distant		 		= Cast<UMaterialInterface>(LoadObject(nullptr, "/Game/MasterMaterials/Generated/Effect/Effect_HazeSphere_Advanced_Distant.Effect_HazeSphere_Advanced_Distant"));
		HazeSphereMaterial_Advanced_Fog_Distant	 		= Cast<UMaterialInterface>(LoadObject(nullptr, "/Game/MasterMaterials/Generated/Effect/Effect_HazeSphere_Advanced_Fog_Distant.Effect_HazeSphere_Advanced_Fog_Distant"));
		HazeSphereMaterial_Advanced_Distant_1x1	 		= Cast<UMaterialInterface>(LoadObject(nullptr, "/Game/MasterMaterials/Generated/Effect/Effect_HazeSphere_Advanced_Distant_1x1.Effect_HazeSphere_Advanced_Distant_1x1"));
		HazeSphereMaterial_Advanced_Fog_Distant_1x1	 	= Cast<UMaterialInterface>(LoadObject(nullptr, "/Game/MasterMaterials/Generated/Effect/Effect_HazeSphere_Advanced_Fog_Distant_1x1.Effect_HazeSphere_Advanced_Fog_Distant_1x1"));

		HazeMeshMaterialPass0 							= Cast<UMaterialInterface>(LoadObject(nullptr, "/Game/MasterMaterials/Generated/Effect/Effect_HazeMesh_Pass0.Effect_HazeMesh_Pass0"));
		HazeMeshMaterialPass1 							= Cast<UMaterialInterface>(LoadObject(nullptr, "/Game/MasterMaterials/Generated/Effect/Effect_HazeMesh_Pass1.Effect_HazeMesh_Pass1"));
		HazeMeshMaterialPass0_Fog 						= Cast<UMaterialInterface>(LoadObject(nullptr, "/Game/MasterMaterials/Generated/Effect/Effect_HazeMesh_Pass0_Fog.Effect_HazeMesh_Pass0_Fog"));
		HazeMeshMaterialPass1_Fog 						= Cast<UMaterialInterface>(LoadObject(nullptr, "/Game/MasterMaterials/Generated/Effect/Effect_HazeMesh_Pass1_Fog.Effect_HazeMesh_Pass1_Fog"));
		
		CubeMesh 			                   			= Cast<UStaticMesh>(LoadObject(nullptr, "/Game/Environment/Blueprints/HazeSphere/HazeCube_Inverted.HazeCube_Inverted"));
		SphereMesh 			                   			= Cast<UStaticMesh>(LoadObject(nullptr, "/Game/Environment/Blueprints/HazeSphere/HazeSphere_lodding.HazeSphere_lodding"));
	}

#endif
#if COOK_COMMANDLET
	void Cook_LoadHazeSphereMaterials()
	{
		HazeSphereMaterial			 			 		= Cast<UMaterialInterface>(LoadObject(nullptr, "/Game/MasterMaterials/Generated/Effect/Effect_HazeSphere.Effect_HazeSphere"));
		HazeSphereMaterial_Inside_Coarse			 	= Cast<UMaterialInterface>(LoadObject(nullptr, "/Game/MasterMaterials/Generated/Effect/Effect_HazeSphere_Inside_Coarse.Effect_HazeSphere_Inside_Coarse"));
		HazeSphereMaterial_HalfSphere			 		= Cast<UMaterialInterface>(LoadObject(nullptr, "/Game/MasterMaterials/Generated/Effect/Effect_HazeSphere_HalfSphere.Effect_HazeSphere_HalfSphere"));
		HazeSphereMaterial_Fog			 		 		= Cast<UMaterialInterface>(LoadObject(nullptr, "/Game/MasterMaterials/Generated/Effect/Effect_HazeSphere_Fog.Effect_HazeSphere_Fog"));
		HazeSphereMaterial_Distant			 	 		= Cast<UMaterialInterface>(LoadObject(nullptr, "/Game/MasterMaterials/Generated/Effect/Effect_HazeSphere_Distant.Effect_HazeSphere_Distant"));
		HazeSphereMaterial_Fog_Distant			 		= Cast<UMaterialInterface>(LoadObject(nullptr, "/Game/MasterMaterials/Generated/Effect/Effect_HazeSphere_Fog_Distant.Effect_HazeSphere_Fog_Distant"));
		HazeSphereMaterial_Distant_1x1		 			= Cast<UMaterialInterface>(LoadObject(nullptr, "/Game/MasterMaterials/Generated/Effect/Effect_HazeSphere_Distant_1x1.Effect_HazeSphere_Distant_1x1"));
		HazeSphereMaterial_Fog_Distant_1x1	 			= Cast<UMaterialInterface>(LoadObject(nullptr, "/Game/MasterMaterials/Generated/Effect/Effect_HazeSphere_Fog_Distant_1x1.Effect_HazeSphere_Fog_Distant_1x1"));
		HazeSphereMaterial_Advanced			 	 		= Cast<UMaterialInterface>(LoadObject(nullptr, "/Game/MasterMaterials/Generated/Effect/Effect_HazeSphere_Advanced.Effect_HazeSphere_Advanced"));
		HazeSphereMaterial_Advanced_Fog			 		= Cast<UMaterialInterface>(LoadObject(nullptr, "/Game/MasterMaterials/Generated/Effect/Effect_HazeSphere_Advanced_Fog.Effect_HazeSphere_Advanced_Fog"));
		HazeSphereMaterial_Advanced_Distant		 		= Cast<UMaterialInterface>(LoadObject(nullptr, "/Game/MasterMaterials/Generated/Effect/Effect_HazeSphere_Advanced_Distant.Effect_HazeSphere_Advanced_Distant"));
		HazeSphereMaterial_Advanced_Fog_Distant	 		= Cast<UMaterialInterface>(LoadObject(nullptr, "/Game/MasterMaterials/Generated/Effect/Effect_HazeSphere_Advanced_Fog_Distant.Effect_HazeSphere_Advanced_Fog_Distant"));
		HazeSphereMaterial_Advanced_Distant_1x1	 		= Cast<UMaterialInterface>(LoadObject(nullptr, "/Game/MasterMaterials/Generated/Effect/Effect_HazeSphere_Advanced_Distant_1x1.Effect_HazeSphere_Advanced_Distant_1x1"));
		HazeSphereMaterial_Advanced_Fog_Distant_1x1	 	= Cast<UMaterialInterface>(LoadObject(nullptr, "/Game/MasterMaterials/Generated/Effect/Effect_HazeSphere_Advanced_Fog_Distant_1x1.Effect_HazeSphere_Advanced_Fog_Distant_1x1"));

		HazeMeshMaterialPass0 							= Cast<UMaterialInterface>(LoadObject(nullptr, "/Game/MasterMaterials/Generated/Effect/Effect_HazeMesh_Pass0.Effect_HazeMesh_Pass0"));
		HazeMeshMaterialPass1 							= Cast<UMaterialInterface>(LoadObject(nullptr, "/Game/MasterMaterials/Generated/Effect/Effect_HazeMesh_Pass1.Effect_HazeMesh_Pass1"));
		HazeMeshMaterialPass0_Fog 						= Cast<UMaterialInterface>(LoadObject(nullptr, "/Game/MasterMaterials/Generated/Effect/Effect_HazeMesh_Pass0_Fog.Effect_HazeMesh_Pass0_Fog"));
		HazeMeshMaterialPass1_Fog 						= Cast<UMaterialInterface>(LoadObject(nullptr, "/Game/MasterMaterials/Generated/Effect/Effect_HazeMesh_Pass1_Fog.Effect_HazeMesh_Pass1_Fog"));
	}
#endif

    UFUNCTION()
    void ConstructionScript_Hack()
    {
		if (World != nullptr && !World.IsGameWorld())
		{
			#if EDITOR
			Editor_LoadHazeSphereMaterials();
			#endif
			#if COOK_COMMANDLET
			Cook_LoadHazeSphereMaterials();
			#endif
		}

		ApplyMeshAndMaterial();
		EnforceCorrectScaling();
    }

	private void ApplyMeshAndMaterial()
	{
        FVector Scale = GetWorldScale();
        float minscale = Math::Min(Scale.X, Math::Min(Scale.Y, Scale.Z));
        float maxscale = Math::Max(Scale.X, Math::Max(Scale.Y, Scale.Z));
		bRenderWhenCameraIsInside = !bBackgroundOnly;

        if(Type == EFogVolume::Sphere)
        {
            Data.Mesh = SphereMesh;
            Data.ScaleType = EScaleType::Uniform;
            Data.RotationType = ERotationType::Locked;
            Data.ScaleFactor = 1.0 * minscale;
			HazeSphereOutsideRadius = minscale * 100.0;
        }
        else if(Type == EFogVolume::HalfSphere)
        {
            Data.Mesh = SphereMesh;
            Data.ScaleType = EScaleType::Uniform;
            Data.RotationType = ERotationType::Locked;
            Data.ScaleFactor = 1.0 * minscale;
			HazeSphereOutsideRadius = 0;
        }
        else if(Type == EFogVolume::Box)
        {
            Data.Mesh = CubeMesh;
            Data.ScaleType = EScaleType::Free;
            Data.RotationType = ERotationType::Free;
            Data.ScaleFactor = 0.7 * Scale.Distance(FVector::ZeroVector);
			HazeSphereOutsideRadius = MAX_flt;
        }
		else if(Type == EFogVolume::Mesh)
		{
			UStaticMeshComponent Pass0 = UStaticMeshComponent::GetOrCreate(Owner, n"HazeMeshPass0");
			UStaticMeshComponent Pass1 = UStaticMeshComponent::GetOrCreate(Owner, n"HazeMeshPass1");
			
			Pass0.SetStaticMesh(Mesh);
			Pass1.SetStaticMesh(Mesh);

			Pass0.SetCullDistance(Data.ScaleFactor * 1500 * CullingDistanceMultiplier);
			Pass1.SetCullDistance(Data.ScaleFactor * 1500 * CullingDistanceMultiplier);

			Pass0.SetTranslucentSortPriority(TranslucencySortPriority);
			Pass1.SetTranslucentSortPriority(TranslucencySortPriority + 5);

			UpdateMaterialParameters(Pass0);
			UpdateMaterialParameters(Pass1);
			if(ApplyFog)
			{
				Pass0.SetMaterial(0, HazeMeshMaterialPass0_Fog);
				Pass1.SetMaterial(0, HazeMeshMaterialPass1_Fog);
			}
			else
			{
				Pass0.SetMaterial(0, HazeMeshMaterialPass0);
				Pass1.SetMaterial(0, HazeMeshMaterialPass1);
			}

			SetStaticMesh(nullptr);
		}

		if(Type != EFogVolume::Mesh)
		{
			SetCullDistance(Data.ScaleFactor * 1500 * CullingDistanceMultiplier);
			bool bIsAdvanced = false;
			if(ColorType != EColorType::Color)
				bIsAdvanced = true;
			if(Type != EFogVolume::Sphere && Type != EFogVolume::HalfSphere)
				bIsAdvanced = true;
			
			SetStaticMesh(Data.Mesh);
			
			if(bIsAdvanced)
			{
				if(ApplyFog)
				{
					SetMaterial(0, HazeSphereMaterial_Advanced_Fog);
					if(bWaterGlitchFix)
					{
						SetMaterial(1, HazeSphereMaterial_Advanced_Fog_Distant_1x1);
						SetMaterial(2, HazeSphereMaterial_Advanced_Fog_Distant_1x1);
					}
					else
					{
						SetMaterial(1, HazeSphereMaterial_Advanced_Fog_Distant);
						SetMaterial(2, HazeSphereMaterial_Advanced_Fog_Distant);
					}
				}
				else
				{
					SetMaterial(0, HazeSphereMaterial_Advanced);
					if(bWaterGlitchFix || bNeverReduceShadingRate)
					{
						SetMaterial(1, HazeSphereMaterial_Advanced_Distant_1x1);
						SetMaterial(2, HazeSphereMaterial_Advanced_Distant_1x1);
					}
					else
					{
						SetMaterial(1, HazeSphereMaterial_Advanced_Distant);
						SetMaterial(2, HazeSphereMaterial_Advanced_Distant);
					}
				}
			}
			else if (Type == EFogVolume::HalfSphere)
			{
				SetMaterial(0, HazeSphereMaterial_HalfSphere);
				SetMaterial(1, HazeSphereMaterial_HalfSphere);
				SetMaterial(2, HazeSphereMaterial_HalfSphere);
			}
			else
			{
				if(ApplyFog)
				{
					SetMaterial(0, HazeSphereMaterial_Fog);
					if(bWaterGlitchFix || bNeverReduceShadingRate)
					{
						SetMaterial(1, HazeSphereMaterial_Fog_Distant_1x1);
						SetMaterial(2, HazeSphereMaterial_Fog_Distant_1x1);
					}
					else
					{
						SetMaterial(1, HazeSphereMaterial_Fog_Distant);
						SetMaterial(2, HazeSphereMaterial_Fog_Distant);
					}
				}
				else
				{
					if(bWaterGlitchFix || bNeverReduceShadingRate)
					{
						SetMaterial(0, HazeSphereMaterial);
						SetMaterial(1, HazeSphereMaterial_Distant_1x1);
						SetMaterial(2, HazeSphereMaterial_Distant_1x1);
					}
					else
					{
						if (bAllowReducedShadingRateWhenInside)
							SetMaterial(0, HazeSphereMaterial_Inside_Coarse);
						else
							SetMaterial(0, HazeSphereMaterial);

						SetMaterial(1, HazeSphereMaterial_Distant);
						SetMaterial(2, HazeSphereMaterial_Distant);
					}
				}
			}
			
			UpdateAllMaterialParameters();
		}
	}

	private void EnforceCorrectScaling()
	{

		if (World != nullptr && !World.IsGameWorld())
		{
			#if EDITOR
			Editor_LoadHazeSphereMaterials();
			#endif
			#if COOK_COMMANDLET
			Cook_LoadHazeSphereMaterials();
			#endif
		}

        FVector Scale = GetWorldScale();
        float minscale = Math::Min(Scale.X, Math::Min(Scale.Y, Scale.Z));
        float maxscale = Math::Max(Scale.X, Math::Max(Scale.Y, Scale.Z));

        if(Type == EFogVolume::Sphere || Type == EFogVolume::HalfSphere)
        {
			float SphereScale = minscale;
			if(Scale.X == Scale.Y && Scale.Z != Scale.Y)
				SphereScale = Scale.Z;
			if(Scale.X == Scale.Z && Scale.Y != Scale.Z)
				SphereScale = Scale.Y;
			if(Scale.Y == Scale.Z && Scale.X != Scale.Z)
				SphereScale = Scale.X;
			// Enforce uniform Scale
			SetWorldScale3D(FVector(SphereScale, SphereScale, SphereScale));
        }

		// Prevent from having negative size
		if(Scale.X < 0.05)
			SetWorldScale3D(FVector(0.05, Scale.Y, Scale.Z));
		if(Scale.Y < 0.05)
			SetWorldScale3D(FVector(Scale.X, 0.05, Scale.Z));
		if(Scale.Z < 0.05)
			SetWorldScale3D(FVector(Scale.X, Scale.Y, 0.05));
	}
    
    UFUNCTION(BlueprintOverride)
	void BeginPlay()
    {
		BlendOpacity = FHazeSphereBlendFloat(Opacity, Opacity);
		BlendSoftness = FHazeSphereBlendFloat(Softness, Softness);
		BlendColorA = FHazeSphereBlendColor(ColorA, ColorA);
		BlendColorB = FHazeSphereBlendColor(ColorB, ColorB);
		BlendMinTemperature = FHazeSphereBlendFloat(MinTemperature, MinTemperature);
		BlendMaxTemperature = FHazeSphereBlendFloat(MaxTemperature, MaxTemperature);
		BlendContrast = FHazeSphereBlendFloat(Contrast, Contrast);
		BlendOffset = FHazeSphereBlendFloat(Offset, Offset);

		if (Opacity <= SMALL_NUMBER)
		{
			AddComponentVisualsBlocker(this);
			SetVisibility(false);
		}
    }

	void UpdateScale()
	{
		Data.ScaleFactor = GetWorldScale().Min;
		SetDefaultCustomPrimitiveDataFloat(8, Data.ScaleFactor);
		HazeSphereOutsideRadius = Data.ScaleFactor * 100.0;
		SetCullDistance(Data.ScaleFactor * 1500 * CullingDistanceMultiplier);
	}

	void UpdateAllMaterialParameters()
	{
		UpdateMaterialParameters(this);
	}
	void UpdateMaterialParameters(UStaticMeshComponent StaticMeshComponent)
	{
		if(StaticMeshComponent == nullptr)
			return;

		if (Opacity <= SMALL_NUMBER)
		{
			// Zero opacity haze spheres just aren't rendered at all
			StaticMeshComponent.AddComponentVisualsBlocker(this);
			StaticMeshComponent.SetVisibility(false);
		}
		else
		{
			StaticMeshComponent.RemoveComponentVisualsBlocker(this);
			StaticMeshComponent.SetVisibility(true);

			StaticMeshComponent.SetDefaultCustomPrimitiveDataFloat(0, float(Type));
			StaticMeshComponent.SetDefaultCustomPrimitiveDataFloat(1, float(ColorType));
			StaticMeshComponent.SetDefaultCustomPrimitiveDataFloat(2, MinTemperature);
			StaticMeshComponent.SetDefaultCustomPrimitiveDataFloat(3, MaxTemperature);
			StaticMeshComponent.SetDefaultCustomPrimitiveDataFloat(4, Opacity);
			StaticMeshComponent.SetDefaultCustomPrimitiveDataFloat(5, Softness);
			StaticMeshComponent.SetDefaultCustomPrimitiveDataFloat(6, Contrast);
			StaticMeshComponent.SetDefaultCustomPrimitiveDataFloat(7, Offset);
			StaticMeshComponent.SetDefaultCustomPrimitiveDataFloat(8, Data.ScaleFactor);
			StaticMeshComponent.SetDefaultCustomPrimitiveDataFloat(9, bLinear ? 1 : 0);

			StaticMeshComponent.SetDefaultCustomPrimitiveDataFloat(10, ColorA.R);
			StaticMeshComponent.SetDefaultCustomPrimitiveDataFloat(11, ColorA.G);
			StaticMeshComponent.SetDefaultCustomPrimitiveDataFloat(12, ColorA.B);
			StaticMeshComponent.SetDefaultCustomPrimitiveDataFloat(13, ColorA.A);
			
			StaticMeshComponent.SetDefaultCustomPrimitiveDataFloat(14, ColorB.R);
			StaticMeshComponent.SetDefaultCustomPrimitiveDataFloat(15, ColorB.G);
			StaticMeshComponent.SetDefaultCustomPrimitiveDataFloat(16, ColorB.B);
			StaticMeshComponent.SetDefaultCustomPrimitiveDataFloat(17, ColorB.A);
			StaticMeshComponent.SetDefaultCustomPrimitiveDataFloat(18, TestOffset);
		}
	}

	void SetEverything(float InOpacity, FLinearColor InColorA, FLinearColor InColorB, float InSoftness, float InMinTemperature, float InMaxTemperature, float InContrast, float InOffset)
	{
		this.Opacity = InOpacity;
		this.Softness = InSoftness;
		this.ColorA = InColorA;
		this.ColorB = InColorB;
		this.Contrast = InContrast;
		this.Offset = InOffset;
		UpdateAllMaterialParameters();
	}


    UFUNCTION()
	void SetGradient(float InOpacity = 1.0,
	FLinearColor InColorA = FLinearColor(0.428691, 0.502887, 0.545725, 1.0),
	FLinearColor InColorB = FLinearColor(0.545725, 0.502887, 0.428691, 1.0),
	float InSoftness = 1.0, float InContrast = 1.0, float InOffset = 0.5)
	{
		ColorType = EColorType::Gradient;
		this.Opacity = InOpacity;
		this.Softness = InSoftness;
		this.ColorA = InColorA;
		this.ColorB = InColorB;
		this.Contrast = InContrast;
		this.Offset = InOffset;
		UpdateAllMaterialParameters();
	}
	
    UFUNCTION()
	void SetGradientOverTime(float Time = 2.0,
	float InOpacity = 1.0,
	FLinearColor InColorA = FLinearColor(0.428691, 0.502887, 0.545725, 1.0),
	FLinearColor InColorB = FLinearColor(0.545725, 0.502887, 0.428691, 1.0),
	float InSoftness = 1.0, float InContrast = 1.0, float InOffset = 0.5)
	{
		ColorType = EColorType::Gradient;

		CurrentLerpTime = Time;
		TotalLerpTime = Time;
		SetComponentTickEnabled(true);

		BlendOpacity = FHazeSphereBlendFloat(this.Opacity, InOpacity);
		BlendSoftness = FHazeSphereBlendFloat(this.Softness, InSoftness);
		BlendContrast = FHazeSphereBlendFloat(this.Contrast, InContrast);
		BlendOffset = FHazeSphereBlendFloat(this.Offset, InOffset);
		BlendColorA = FHazeSphereBlendColor(this.ColorA, InColorA);
		BlendColorB = FHazeSphereBlendColor(this.ColorB, InColorB);
	}
	
    UFUNCTION()
	void SetTemperature(float InOpacity = 1.0, float InMinTemperature = 0.0, float InMaxTemperature = 5000.0, float InSoftness = 1.0, float InContrast = 1.0, float InOffset = 0.5)
	{
		ColorType = EColorType::Temperature;
		this.Opacity = InOpacity;
		this.Softness = InSoftness;
		this.MinTemperature = InMinTemperature;
		this.MaxTemperature = InMaxTemperature;
		this.Contrast = InContrast;
		this.Offset = InOffset;
		UpdateAllMaterialParameters();
	}
	
    UFUNCTION()
	void SetTemperatureOverTime(float InTime = 2.0, float InOpacity = 1.0, float InMinTemperature = 0.0, float InMaxTemperature = 5000.0, float InSoftness = 1.0, float InContrast = 1.0, float InOffset = 0.5)
	{
		ColorType = EColorType::Temperature;

		CurrentLerpTime = InTime;
		TotalLerpTime = InTime;
		SetComponentTickEnabled(true);

		BlendOpacity = FHazeSphereBlendFloat(this.Opacity, InOpacity);
		BlendSoftness = FHazeSphereBlendFloat(this.Softness, InSoftness);
		BlendContrast = FHazeSphereBlendFloat(this.Contrast, InContrast);
		BlendOffset = FHazeSphereBlendFloat(this.Offset, InOffset);
		BlendMinTemperature = FHazeSphereBlendFloat(this.MinTemperature, InMinTemperature);
		BlendMaxTemperature = FHazeSphereBlendFloat(this.MaxTemperature, InMaxTemperature);
	}


    UFUNCTION()
	void SetColor(float InOpacity = 1.0, float InSoftness = 1.0, FLinearColor InColor = FLinearColor(0.428691, 0.502887, 0.545725, 1.0))
	{
		ColorType = EColorType::Color;
		this.Opacity = InOpacity;
		this.Softness = InSoftness;
		this.ColorA = InColor;
		UpdateAllMaterialParameters();
	}

    UFUNCTION()
	void SetColorOverTime(float Time = 2.0, float InOpacity = 1.0, float InSoftness = 1.0, FLinearColor InColor = FLinearColor(0.428691, 0.502887, 0.545725, 1.0))
	{
		ColorType = EColorType::Color;
		CurrentLerpTime = Time;
		TotalLerpTime = Time;
		SetComponentTickEnabled(true);

		BlendColorA = FHazeSphereBlendColor(this.ColorA, InColor);
		BlendOpacity = FHazeSphereBlendFloat(this.Opacity, InOpacity);
		BlendSoftness = FHazeSphereBlendFloat(this.Softness, InSoftness);
	}
	

    UFUNCTION()
	void SetOpacityValue(float InOpacity = 1.0)
	{
		if (Opacity == InOpacity)
			return;
		this.Opacity = InOpacity;
		UpdateAllMaterialParameters();
	}

    UFUNCTION()
	void SetOpacityOverTime(float Time = 2.0, float InOpacity = 1.0)
	{
		CurrentLerpTime = Time;
		TotalLerpTime = Time;
		SetComponentTickEnabled(true);
		BlendOpacity = FHazeSphereBlendFloat(this.Opacity, InOpacity);
		UpdateAllMaterialParameters();
	}

    UFUNCTION()
	void SetSoftnessValue(float InSoftness = 1.0)
	{
		this.Softness = InSoftness;
		UpdateAllMaterialParameters();
	}

    UFUNCTION()
	void SetSoftnessOverTime(float Time = 2.0, float InSoftness = 1.0)
	{
		CurrentLerpTime = Time;
		TotalLerpTime = Time;
		SetComponentTickEnabled(true);
		BlendSoftness = FHazeSphereBlendFloat(this.Softness, InSoftness);
		UpdateAllMaterialParameters();
	}

    UFUNCTION(BlueprintOverride)
	void Tick(float DeltaTime)
    {
		if(CurrentLerpTime > 0)
		{
			CurrentLerpTime -= DeltaTime;
			float NormalizedLerpTime = 1.0 - Math::Clamp(CurrentLerpTime / TotalLerpTime, 0.0, 1.0);
			SetEverything(	BlendOpacity.Blend(NormalizedLerpTime),
							BlendColorA.Blend(NormalizedLerpTime), 
							BlendColorB.Blend(NormalizedLerpTime), 
							BlendSoftness.Blend(NormalizedLerpTime), 
							BlendMinTemperature.Blend(NormalizedLerpTime),
							BlendMaxTemperature.Blend(NormalizedLerpTime),
							BlendContrast.Blend(NormalizedLerpTime),
							BlendOffset.Blend(NormalizedLerpTime)
			);
		}
		else
		{
			SetComponentTickEnabled(false);
		}
    }
}

UCLASS(Abstract, hidecategories="StaticMesh Materials Physics Collision Lighting Physics Activation Cooking Replication Input Actor HLOD Mobile AssetUserData DataLayers Tags WorldPartition Debug VirtualTexture Navigation")
class AHazeSphere : AHazeActor
{
    UPROPERTY(DefaultComponent, RootComponent, ShowOnActor)
    UHazeSphereComponent HazeSphereComponent;
	
#if EDITOR
    UPROPERTY(DefaultComponent)
    UBillboardComponent Billboard;
	default Billboard.bIsEditorOnly = true;
	default Billboard.bUseInEditorScaling = true;

    UPROPERTY(EditAnywhere)
	float EditorBillboardScale = 1.0;
#endif

    UFUNCTION(BlueprintOverride)
    void ConstructionScript()
    {
#if EDITOR
		Billboard.SetWorldScale3D(FVector::OneVector * EditorBillboardScale);
#endif
		HazeSphereComponent.ConstructionScript_Hack();
    }
}

#if EDITOR
struct FHazeSphereOverlapError
{
	TWeakObjectPtr<UHazeSphereComponent> ErrorSphere;
	TArray<TWeakObjectPtr<UHazeSphereComponent>> Overlaps;
	FString ErrorText;
}

struct FHazeSphereOverlapProcessData
{
	TWeakObjectPtr<UHazeSphereComponent> Sphere;
	TArray<int> OverlappingSpheres;
}

class UHazeSphereEditorSubsystem : UHazeEditorSubsystem
{
	const bool bDoWarning = false; // YLVA DONT COMMIT
	const int MaximumOverlaps = 1;
	bool bLevelsChanged = false;
	bool bDirtyOverlappingHazeSpheres = false;

	bool bExpanded = true;
	bool bVisualize = false;

	TArray<FHazeSphereOverlapError> OverlapErrors;
	TSet<TWeakObjectPtr<UHazeSphereComponent>> ErrorSpheres;
	TSet<TWeakObjectPtr<UHazeSphereComponent>> OverlappingSpheres;

	UFUNCTION(BlueprintOverride)
	void OnEditorLevelsChanged()
	{
		bLevelsChanged = true;
		bVisualize = false;
	}

	void DrawErrorVisualization()
	{
		for (auto WeakSphere : ErrorSpheres)
		{
			UHazeSphereComponent Sphere = WeakSphere.Get();
			if (Sphere == nullptr)
				continue;

			Debug::DrawDebugSolidSphere(Sphere.WorldLocation, Sphere.WorldScale.AbsMax * 100.0, FLinearColor(1.00, 0.73, 0.00, 0.5));
		}

		for (auto WeakSphere : OverlappingSpheres)
		{
			UHazeSphereComponent Sphere = WeakSphere.Get();
			if (Sphere == nullptr)
				continue;
			if (ErrorSpheres.Contains(Sphere))
				continue;

			Debug::DrawDebugSolidSphere(Sphere.WorldLocation, Sphere.WorldScale.AbsMax * 100.0, FLinearColor(0.85, 0.81, 0.71, 0.50));
		}
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaTime)
	{
		if (!bDoWarning)
			return;
		if (bLevelsChanged || bDirtyOverlappingHazeSpheres)
		{
			UpdateOverlappingHazeSpheres();
			bLevelsChanged = false;
			bDirtyOverlappingHazeSpheres = false;
		}

		if (OverlapErrors.Num() != 0 && !Editor::IsPlaying() && !Editor::IsLevelEditorInGameView())
		{
			auto Drawer = GetEditorViewportOverlay();
			if (Drawer.IsVisible())
			{
				auto Canvas = Drawer.BeginCanvasPanel();

				auto VBox = Canvas
					.SlotAnchors(1, 0, 1, 1)
					.SlotAlignment(1, 0)
					.SlotOffset(0, 50, 0, 50)
					.SlotAutoSize(true)
					.VerticalBox()
					;

				auto Header = VBox
					.BorderBox()
						.SlotPadding(2)
						.BackgroundColor(FLinearColor(0.00, 0.00, 0.00))
					.BorderBox()
						.MinDesiredWidth(600)
						.BackgroundColor(FLinearColor(0.15, 0.13, 0.13))
					.HorizontalBox();
				Header
					.SlotVAlign(EVerticalAlignment::VAlign_Center)
					.SlotPadding(10, 0)
					.SlotFill()
					.Text(f"{OverlapErrors.Num()} HazeSphere(s) are overlapping too many other HazeSpheres")	
						.Color(FLinearColor(1.00, 0.60, 0.00))
						.Scale(1.5);
				VBox.Spacer(10);

				auto VisualizeCheckbox = Header.CheckBox().Label("Visualize").Checked(bVisualize);
				bVisualize = VisualizeCheckbox;
				Header.Spacer(10);

				if (bVisualize)
					DrawErrorVisualization();

				if (Header.Button(bExpanded ? "^" : "V"))
					bExpanded = !bExpanded;

				if (bExpanded)
				{
					for (int i = 0; i < Math::Min(OverlapErrors.Num(), 30); ++i)
					{
						auto Row = VBox
							.SlotPadding(10, 0)
							.BorderBox()
								.BackgroundColor(FLinearColor(0.06, 0.06, 0.06))
								.SlotPadding(0, 3)
								.HorizontalBox()
							;

						auto ZoomToButton = Row.SlotPadding(10, 0, 5, 0)
							.Button("🔍")
							.Padding(0)
							.Tooltip("Focus viewport on haze spheres")
						;

						auto SelectButton = Row.SlotPadding(0, 0, 5, 0)
							.Button("🔗")
							.Padding(0)
							.Tooltip("Select overlapping haze spheres")
						;

						if (ZoomToButton.WasClicked() || SelectButton.WasClicked())
						{
							TArray<AActor> Actors;
							if (OverlapErrors[i].ErrorSphere.IsValid())
								Actors.Add(OverlapErrors[i].ErrorSphere.Get().Owner);
							for (auto Overlap : OverlapErrors[i].Overlaps)
							{
								if (Overlap.IsValid())
									Actors.Add(Overlap.Get().Owner);
							}

							Editor::SelectActors(Actors, ZoomToButton);
						}

						Row.SlotPadding(0)
							.SlotVAlign(EVerticalAlignment::VAlign_Center)
							.Text(OverlapErrors[i].ErrorText)
								.Color(FLinearColor(1.00, 0.73, 0.00))
								.ShadowColor(FLinearColor::Black)
								.ShadowOffset(FVector2D(1, 1))
								.Bold()
						;
					}

					if (OverlapErrors.Num() > 30)
					{
						VBox
							.SlotPadding(0)
							.Text(f"... {OverlapErrors.Num() - 30} More")
							.Color(FLinearColor(1.00, 0.73, 0.00))
							.ShadowColor(FLinearColor::Black)
							.ShadowOffset(FVector2D(1, 1))
							.Bold()
							;
					}
				}
				
				Drawer.End();
			}
		}
	}

	void UpdateOverlappingHazeSpheres()
	{
		TArray<UHazeSphereComponent> HazeSpheres;
		HazeSpheres = Editor::GetAllEditorWorldComponentsOfClass(UHazeSphereComponent);

		TArray<FHazeSphereOverlapProcessData> ProcessData;
		TArray<FVector4f> Positions;
		
		OverlapErrors.Reset();
		ErrorSpheres.Reset();
		OverlappingSpheres.Reset();

		float StartTime = Time::PlatformTimeSeconds;

		// Ignore haze spheres that are set to background only, we don't care if those overlap,
		// since the camera will never be inside them (they can still be expensive by being huge, but we'll see)
		for (int i = HazeSpheres.Num() - 1; i >= 0; --i)
		{
			if (HazeSpheres[i].bBackgroundOnly)
				continue;
			if (HazeSpheres[i].Type != EFogVolume::Sphere)
				continue;
			if (HazeSpheres[i].IsTransient())
				continue;

			FHazeSphereOverlapProcessData Data;
			Data.Sphere = HazeSpheres[i];
			ProcessData.Add(Data);

			FVector4f Position(FVector3f(HazeSpheres[i].WorldLocation), float32(HazeSpheres[i].WorldScale.AbsMax * 100.0));
			Positions.Add(Position);
		}

		// Create a structure of overlaps between spheres
		int SphereCount = Positions.Num();
		for (int CheckIndex = 0; CheckIndex < SphereCount; ++CheckIndex)
		{
			FVector4f CheckSphere = Positions[CheckIndex];
			FVector3f CheckPosition(CheckSphere.X, CheckSphere.Y, CheckSphere.Z);

			for (int OtherIndex = CheckIndex + 1; OtherIndex < SphereCount; ++OtherIndex)
			{
				FVector4f OtherSphere = Positions[OtherIndex];
				FVector3f OtherPosition(OtherSphere.X, OtherSphere.Y, OtherSphere.Z);
				
				if (OtherPosition.Distance(CheckPosition) < OtherSphere.W + CheckSphere.W)
				{
					ProcessData[CheckIndex].OverlappingSpheres.AddUnique(OtherIndex);
					ProcessData[OtherIndex].OverlappingSpheres.AddUnique(CheckIndex);
				}
			}
		}

		// Find cases where 3 spheres are all overlapping each other
		for (int CheckIndex = 0; CheckIndex < SphereCount; ++CheckIndex)
		{
			FHazeSphereOverlapProcessData& CheckData = ProcessData[CheckIndex];
			int OverlapCount = CheckData.OverlappingSpheres.Num();
			bool bMarkedError = false;

			for (int FirstOverlapIndex = 0; FirstOverlapIndex < OverlapCount && !bMarkedError; ++FirstOverlapIndex)
			{
				int FirstOverlapId = CheckData.OverlappingSpheres[FirstOverlapIndex];

				// Ignore overlaps before us in the list, we've already checked these beforehand
				if (FirstOverlapId < CheckIndex)
					continue;

				// Check if we have a second overlap sphere that overlaps the other one as well
				for (int SecondOverlapIndex = FirstOverlapIndex; SecondOverlapIndex < OverlapCount && !bMarkedError; ++SecondOverlapIndex)
				{
					int SecondOverlapId = CheckData.OverlappingSpheres[SecondOverlapIndex];

					// Ignore overlaps before us in the list, we've already checked these beforehand
					if (SecondOverlapId < CheckIndex)
						continue;

					if (ProcessData[FirstOverlapId].OverlappingSpheres.Contains(SecondOverlapId))
					{
						// Check if we have a second overlap sphere that overlaps the other one as well
						for (int ThirdOverlapIndex = SecondOverlapIndex; ThirdOverlapIndex < OverlapCount && !bMarkedError; ++ThirdOverlapIndex)
						{
							int ThirdOverlapId = CheckData.OverlappingSpheres[ThirdOverlapIndex];

							// Ignore overlaps before us in the list, we've already checked these beforehand
							if (ThirdOverlapId < CheckIndex)
								continue;

							if (ProcessData[FirstOverlapId].OverlappingSpheres.Contains(ThirdOverlapId)
								&& ProcessData[SecondOverlapId].OverlappingSpheres.Contains(ThirdOverlapId))
							{
								// Check if we have a second overlap sphere that overlaps the other one as well
								for (int FourthOverlapIndex = ThirdOverlapIndex; FourthOverlapIndex < OverlapCount && !bMarkedError; ++FourthOverlapIndex)
								{
									int FourthOverlapId = CheckData.OverlappingSpheres[FourthOverlapIndex];

									// Ignore overlaps before us in the list, we've already checked these beforehand
									if (FourthOverlapId < CheckIndex)
										continue;

									if (ProcessData[FirstOverlapId].OverlappingSpheres.Contains(FourthOverlapId)
										&& ProcessData[SecondOverlapId].OverlappingSpheres.Contains(FourthOverlapId)
										&& ProcessData[ThirdOverlapId].OverlappingSpheres.Contains(FourthOverlapId))
									{
										ErrorSpheres.Add(CheckData.Sphere);
										OverlappingSpheres.Add(ProcessData[FirstOverlapId].Sphere.Get());
										OverlappingSpheres.Add(ProcessData[SecondOverlapId].Sphere.Get());
										OverlappingSpheres.Add(ProcessData[ThirdOverlapId].Sphere.Get());
										OverlappingSpheres.Add(ProcessData[FourthOverlapId].Sphere.Get());

										FHazeSphereOverlapError Error;
										Error.ErrorSphere = CheckData.Sphere;
										Error.Overlaps.Add(ProcessData[FirstOverlapId].Sphere.Get());
										Error.Overlaps.Add(ProcessData[SecondOverlapId].Sphere.Get());
										Error.Overlaps.Add(ProcessData[ThirdOverlapId].Sphere.Get());
										Error.Overlaps.Add(ProcessData[FourthOverlapId].Sphere.Get());
										Error.ErrorText = f"{CheckData.Sphere.Get().Owner.ActorNameOrLabel} is overlapping too many other HazeSpheres";
										OverlapErrors.Add(Error);
										bMarkedError = true;
									}
								}
							}
						}
					}
				}
			}
		}

		float EndTime = Time::PlatformTimeSeconds;
		//Log(f"Calculating haze sphere overlaps took {(EndTime - StartTime) * 1000 :.3} ms");
	}
}
#endif
