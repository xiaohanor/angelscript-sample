const FConsoleVariable CVar_GameSkyShadowCascadeQuality("Haze.GameSkyShadowCascadeQuality", 2);
const FConsoleVariable CVar_PreviewGameSkyCascadesInEditor("Haze.PreviewGameSkyCascadesInEditor", 1);

enum ESkyCascadeShadowSettings
{
	Off,
	StandardCascades,
	StandardCascades_NotOnMedium,
	StandardCascades_OnlyOnUltra,
	CanopyCascadesOnHighOnly,
	CutsceneQuality UMETA(Hidden),
};

struct FHazeLightingConfig
{
	UPROPERTY(EditAnywhere, Category="Lighting Config")
	float SkyLightIntensity = 1.0;

	UPROPERTY(EditAnywhere, Category="Lighting Config")
	FLinearColor LightColor = FLinearColor(1, 1, 1, 1);

	UPROPERTY(EditAnywhere, Category="Lighting Config")
	float LightIntensity = 6.0;

	UPROPERTY(EditAnywhere, Category="Lighting Config")
	UTexture SkyTexture;

	UPROPERTY(EditAnywhere, Category="Lighting Config")
	FFogParameters Fog;

	UPROPERTY(EditAnywhere, Category="Lighting Config")
	AHazePostProcessVolume PostProcess;

	UPROPERTY(EditAnywhere, Category="Lighting Config")
	TArray<AHazeSphere> HazeSpheres;

	UPROPERTY(EditAnywhere, Category="Lighting Config")
	TArray<ALight> Lights;
	UPROPERTY(EditAnywhere, Category="Lighting Config")
	float HDRIntensity = 2.0;

	UPROPERTY(EditAnywhere, Category="Lighting Config")
	FLinearColor SkyTint = FLinearColor(0.5, 0.5, 0.5, 1);

	UPROPERTY(EditAnywhere, Category="Lighting Config")
	float LightShaftIntensity = 0.001;

	UPROPERTY(EditAnywhere, Category="Lighting Config")
	FLinearColor LightShaftTint = FLinearColor(1,1,1,1);
	
}


struct FFogParameters
{
	UPROPERTY(EditAnywhere)
	float Density = 0.01;
	
	UPROPERTY(EditAnywhere)
	float HeightOffset = 0.0;
	
	UPROPERTY(EditAnywhere)
	float HeightFalloff = 0.2;
	
	UPROPERTY(EditAnywhere)
	float MaxOpacity = 1.0;
	
	UPROPERTY(EditAnywhere)
	float StartDistance = 0.0;
	
	UPROPERTY(EditAnywhere)
	FLinearColor Color = FLinearColor(0.742727, 0.863819, 1, 1);
	
	UPROPERTY(EditAnywhere)
	bool DirectionalColorEnabled = false;
	
	UPROPERTY(EditAnywhere)
	FLinearColor DirectionalColor = FLinearColor(1.0, 0.729333, 0.370158, 1);
	
	UPROPERTY(EditAnywhere)
	float DirectionalStartDistance = 5000.0;
	
	UPROPERTY(EditAnywhere)
	float DirectionalTightness = 4.0;

	UPROPERTY(EditAnywhere)
	float CutoffDistance = 0.0;
}

namespace AGameSky
{
	/**
	 * Get the current sky that is active in the level.
	 */
	AGameSky Get()
	{
		if (!ActorList::CanUseListedActors())
			return nullptr;
		return ActorList::GetSingle(AGameSky);
	}
}

UFUNCTION(BlueprintPure)
AGameSky GetSky()
{
	return AGameSky::Get();
}

UCLASS(Abstract, HideCategories = "Rendering Collision Debug Actor Cooking Streaming")
class AGameSky : AHazeActor
{
    UPROPERTY(DefaultComponent, RootComponent)
    USceneComponent Root;
    default Root.Mobility = EComponentMobility::Static;
	
#if EDITOR
    UPROPERTY(DefaultComponent, BlueprintHidden, NotEditable)
    USceneCaptureComponent2D RainMaskSceneCaptureComponent;
	default RainMaskSceneCaptureComponent.bCaptureEveryFrame = false;
	default RainMaskSceneCaptureComponent.bCaptureOnMovement = false;
#endif
	
	//UPROPERTY(DefaultComponent)
    UPROPERTY(DefaultComponent, BlueprintHidden, NotEditable)
    UDirectionalLightComponent DirectionalLight;
    default DirectionalLight.Mobility = EComponentMobility::Stationary;
    
    //UPROPERTY(DefaultComponent)
    UPROPERTY(DefaultComponent, BlueprintHidden, NotEditable)
    UExponentialHeightFogComponent ExponentialHeightFog;
    
    //UPROPERTY(DefaultComponent)
    UPROPERTY(DefaultComponent, BlueprintHidden, NotEditable)
    USkyLightComponent SkyLight;
	
    //UPROPERTY(DefaultComponent)
    UPROPERTY(DefaultComponent, BlueprintHidden, NotEditable)
	UStaticMeshComponent Skydome;
    default Skydome.Mobility = EComponentMobility::Static;
	default Skydome.CollisionProfileName = n"NoCollision";
	default Skydome.CastShadow = false;
	default Skydome.bCanEverAffectNavigation = false;

    //UPROPERTY(DefaultComponent)
    UPROPERTY(DefaultComponent, BlueprintHidden, NotEditable)
	UStaticMeshComponent SkydomeLowerHemisphere;
    default SkydomeLowerHemisphere.Mobility = EComponentMobility::Static;
	default SkydomeLowerHemisphere.CollisionProfileName = n"NoCollision";
	default SkydomeLowerHemisphere.CastShadow = false;
	default SkydomeLowerHemisphere.bCanEverAffectNavigation = false;

    //UPROPERTY(DefaultComponent)
    UPROPERTY(DefaultComponent, BlueprintHidden, NotEditable)
	UStaticMeshComponent SkydomeSun;
    default SkydomeSun.Mobility = EComponentMobility::Static;
	default SkydomeSun.CollisionProfileName = n"NoCollision";
	default SkydomeSun.CastShadow = false;
	default SkydomeSun.bCanEverAffectNavigation = false;

    UPROPERTY()
	UMaterialInterface SkydomeSunMaterial;

	//UPROPERTY(DefaultComponent, Attach = Root)
	UPROPERTY(DefaultComponent, Attach = Root, BlueprintHidden, NotEditable)
	UArrowComponent Arrow;

	UPROPERTY(DefaultComponent, Attach = Root, BlueprintHidden, NotEditable)
	UGameSkyTickInEditorComponent GameSkyTickInEditorComponent;

	UPROPERTY(DefaultComponent, BlueprintHidden, NotEditable)
	UHazeListedActorComponent ListedComp;

	UPROPERTY(DefaultComponent)
	UDynamicWaterEffectControllerComponent DynamicWaterEffectControllerComponent;

	UPROPERTY(EditAnywhere, Category="Features")
	bool DirectionalLightEnabled = true;

	UPROPERTY(EditAnywhere, Category="Features")
	bool SkyLightEnabled = true;

	UPROPERTY(EditAnywhere, Category="Features")
	bool FogEnabled = true;

	UPROPERTY(EditAnywhere, Category="Features")
	bool SkydomeEnabled = true;

	UPROPERTY(EditAnywhere, Category="Features")
	bool SkydomeSunEnabled = true;

	UPROPERTY(EditAnywhere, Category="Sky Directional Light")
	EComponentMobility DirectionalLightMobility = EComponentMobility::Stationary;

	UPROPERTY(EditAnywhere, Category="Sky Directional Light")
	bool LightUseTemperature = false;

	UPROPERTY(EditAnywhere, Category="Sky Directional Light")
	float LightTemperature = 5500;

	UPROPERTY(EditAnywhere, Category="Sky Directional Light")
	float LightIntensity = 6.0;

	UPROPERTY(EditAnywhere, Category="Sky Directional Light")
	FLinearColor LightTint = FLinearColor(1,1,1,1);

	UPROPERTY(EditAnywhere, Category="Sky Directional Light")
	float LightShaftIntensity = 0.001;

	UPROPERTY(EditAnywhere, Category="Sky Directional Light")
	FLinearColor LightShaftTint = FLinearColor(1,1,1,1);

	UPROPERTY(EditAnywhere, Category="Sky Directional Light")
	float IndirectLightingIntensity = 1.0;

	UPROPERTY(EditAnywhere, Category="Sky Directional Light")
	UMaterialInterface LightMaterialFunction;

	UPROPERTY(EditAnywhere, Category="Sky Directional Light")
	ESkyCascadeShadowSettings SkyCascadeShadows = ESkyCascadeShadowSettings::Off;

	UPROPERTY(EditAnywhere, Category="Sky Directional Light")
	float ShadowAmount = 1.0;

	UPROPERTY(EditAnywhere, Category="Sky Directional Light")
	float SpecularScale = 1.0;

	UPROPERTY(EditAnywhere, Category="Sky Directional Light")
	float ShadowResolutionScale = 1.0;

	UPROPERTY(EditAnywhere, Category="Sky Directional Light")
	float ShadowBias = 0.5;

	UPROPERTY(EditAnywhere, Category="Sky Directional Light")
	float ShadowSlopeBias = 0.5;

	UPROPERTY(EditAnywhere, Category="Sky Directional Light")
	float ShadowSharpen = 0;

	UPROPERTY(EditAnywhere, Category="Sky Directional Light")
	float ContactShadowLength = 0.05;
	UPROPERTY(EditAnywhere, Category="Sky Directional Light")
	float ContactShadowIntensity = 0.9;

	UPROPERTY(EditAnywhere, Category="Sky Directional Light")
	bool CastTranslucentShadows = true;

	UPROPERTY(EditAnywhere, Category="Sky Directional Light")
	bool AffectDynamicIndirectLighting = true;

	UPROPERTY(EditAnywhere, Category="Sky Directional Light|Lightmass")
	float LightSourceAngle = 1.0;
	
	UPROPERTY(EditAnywhere, Category="Sky Directional Light|Lightmass")
	float IndirectLightingSaturation = 1.0;

	UPROPERTY(EditAnywhere, Category="Sky Directional Light|Lightmass")
	float ShadowExponent = 2.0;
	
	UPROPERTY(EditAnywhere, Category="Sky Directional Light|Lightmass")
	bool bUseAreaShadowsForStationaryLight = false;

	UPROPERTY(EditAnywhere, Category="Skydome")
	UTexture SkyTexture;

	UPROPERTY(EditAnywhere, Category="Skydome")
	float HDRIntensity = 2.0;

	UPROPERTY(EditAnywhere, Category="Skydome")
	bool bUseIntensityOverride = false;

	UPROPERTY(EditAnywhere, Category="Skydome", meta=(UIMin=0, UIMax=360))
	float Angle = 0.0;

	UPROPERTY(EditAnywhere, Category="Skydome")
	FLinearColor SkyTint = FLinearColor(0.5, 0.5, 0.5, 1);

	UPROPERTY(EditAnywhere, Category="Skydome")
	FLinearColor SkyDirectionTint = FLinearColor(0.5, 0.5, 0.5, 1);

	UPROPERTY(Category="Skydome")
	UMaterialInterface SkyMaterial;

	UPROPERTY(EditAnywhere, Category="Skydome")
	UMaterialInstanceDynamic SkyMaterialDynamic;

	UPROPERTY(EditAnywhere, Category="Skydome")
	float SkydomeScale = 1.0;

	UPROPERTY(EditAnywhere, Category="Skydome")
	bool LowerHemisphereMesh = false;

	UPROPERTY(EditAnywhere, Category="Skydome")
	bool bLowerHemisphereMeshUseSkyMaterial = false;
	
	UPROPERTY(EditAnywhere, Category="Skydome")
	bool SkyTextureIs360 = false;
	
	UPROPERTY(EditAnywhere, Category="Skydome Sun")
	FLinearColor SunTint = FLinearColor(1, 1, 1, 1);

	UPROPERTY(EditAnywhere, Category="Skydome Sun")
	float SunFlareIntensity = 1.0;

	UPROPERTY(EditAnywhere, Category="Skydome Sun")
	float SunOffsetX = 0.0;

	UPROPERTY(EditAnywhere, Category="Skydome Sun")
	float SunOffsetY = 0.0;

	UPROPERTY(Category="Skydome Sun")
	UMaterialInstanceDynamic SunMaterialDynamic;
	
	UPROPERTY(EditAnywhere, Category="Sky Ambient Light")
	EComponentMobility SkyLightMobility = EComponentMobility::Stationary;

	UPROPERTY(EditAnywhere, Category="Sky Ambient Light")
	ESkyLightSourceType SkyLightSourceType;

	UPROPERTY(EditAnywhere, Category="Sky Ambient Light")
	UTextureCube SLS_Cubemap;

	UPROPERTY(EditAnywhere, Category="Sky Ambient Light")
	bool RealTimeCapture = false;

	UPROPERTY(EditAnywhere, Category="Sky Ambient Light")
	float SourceCubemapAngle = 0.0;

	UPROPERTY(EditAnywhere, Category="Sky Ambient Light")
	int CubemapResolution = 128;

	UPROPERTY(EditAnywhere, Category="Sky Ambient Light")
	float SkyDistanceThreshold = 150000.0;

	UPROPERTY(EditAnywhere, Category="Sky Ambient Light")
	float SkyLightIntensity = 1.0;
	
	UPROPERTY(EditAnywhere, Category="Sky Ambient Light")
	FLinearColor LightColor = FLinearColor(1, 1, 1, 1);



	UPROPERTY(EditAnywhere, Category="Alternate Lighting")
	bool PreviewAlternateLighting = false;

	UPROPERTY(EditAnywhere, Category="Alternate Lighting")
	float AlternateSkyLightIntensity = 1.0;

	UPROPERTY(EditAnywhere, Category="Alternate Lighting")
	FLinearColor AlternateLightColor = FLinearColor(1, 1, 1, 1);

	UPROPERTY(EditAnywhere, Category="Alternate Lighting")
	float AlternateLightIntensity = 6.0;

	UPROPERTY(EditAnywhere, Category="Alternate Lighting")
	FLinearColor AlternateLightShaftTint = FLinearColor(1, 1, 1, 1);

	UPROPERTY(EditAnywhere, Category="Alternate Lighting")
	float AlternateLightShaftIntensity = 6.0;

	UPROPERTY(EditAnywhere, Category="Alternate Lighting")
	UTexture SkyTextureAlternate;

	UPROPERTY(EditAnywhere, Category="Alternate Lighting")
	FFogParameters AlternateFog;

	UPROPERTY(EditAnywhere, Category="Alternate Lighting")
	int LightingConfigPreview = -1;

	UPROPERTY(EditAnywhere, Category="Alternate Lighting")
	TArray<FHazeLightingConfig> LightingConfigs;
	
	FHazeLightingConfig LightingConfigCurrent;
	FHazeLightingConfig LightingConfigOriginal;
	FHazeLightingConfig LightingConfigLast;

	UPROPERTY(EditAnywhere, Category="Sky Ambient Light")
	bool AffectsWorld = true;

	UPROPERTY(EditAnywhere, Category="Sky Ambient Light")
	bool CastShadows = true;

	UPROPERTY(EditAnywhere, Category="Sky Ambient Light")
	float SkyLightIndirectLightingIntensity = 1.0;

	UPROPERTY(EditAnywhere, Category="Sky Ambient Light")
	FLinearColor LowerHemisphereColor = FLinearColor(0,0,0,1);


	UPROPERTY(Category="Sky Ambient Light")
	UMaterialInterface SkyLowerHemisphereMaterial;
	
	UPROPERTY(Category="Sky Ambient Light")
	UMaterialInstanceDynamic SkydomeLowerHemisphereMaterialDynamic;


	UPROPERTY(EditAnywhere, Category="Sky Ambient Light")
	bool LowerHemisphereIsBlack = true;

	UPROPERTY(EditAnywhere, Category="Sky Ambient Light|Occlusion")
	float OcclusionMaxDistance = 1000.0;

	UPROPERTY(EditAnywhere, Category="Sky Ambient Light|Occlusion")
	float OcclusionContrast = .0;

	UPROPERTY(EditAnywhere, Category="Sky Ambient Light|Occlusion")
	float OcclusionExponent = 1.0;

	UPROPERTY(EditAnywhere, Category="Sky Ambient Light|Occlusion")
	float MinOcclusion = 0.0;

	UPROPERTY(EditAnywhere, Category="Sky Ambient Light|Occlusion")
	EOcclusionCombineMode OcclusionCombineMode = EOcclusionCombineMode::OCM_Minimum;

	UPROPERTY(EditAnywhere, Category="Sky Ambient Light|Occlusion")
	FColor OcclusionTint;
	
	UPROPERTY(EditAnywhere, Category="Wind")
	FVector WindDirection = FVector(1, 0, 0);

	UPROPERTY(EditAnywhere, Category="Wind", Interp)
	float WindStrength = 1.0;
	float WindStrengthCurrent = 1.0;

	UPROPERTY(EditAnywhere, Category="Wind", Interp)
	float WindGusts = 1.0;
	float WindGustsCurrent = 1.0;

    UPROPERTY(EditAnywhere, Category="Wind")
	float ClothWindStrength = 1.0;

	UPROPERTY(EditAnywhere, Category="Wind")
	float BushWobblePlayerSizeMultiplier = 1.0;

	UPROPERTY(DefaultComponent)
	UGlobalRainComponent GlobalRainComponent;

	UPROPERTY(EditAnywhere, Interp, Category="Misc")
	float WhitespaceBlend = 1.0;

	UPROPERTY(EditAnywhere, Interp, Category="Misc")
	float WhitespaceTiling = 1.0;

	UPROPERTY(EditAnywhere, Interp, Category="Misc")
	float WhitespaceBorderWidth = 1.0;

	UPROPERTY(EditAnywhere, Category="Fog")
	FFogParameters Fog;

	UPROPERTY(EditAnywhere, Category="Fog")
	bool FirstRotationSet = false;

	UPROPERTY(EditAnywhere, Category="Water")
	float OceanOpacityDepth = 5000.0;

	UPROPERTY(EditAnywhere, Category="Water")
	float OceanMinOpacity = 0.0;

	UPROPERTY(EditAnywhere, Category="Water")
	float OceanMaxOpacity = 1.0;
	
	UPROPERTY()
	UMaterialParameterCollection GlobalParameters;

	UPROPERTY()
	UMaterialParameterCollection WindParameters;

	private FRotator LastRotation;
	private int ActiveCascadeQuality = -1;
	private ESkyCascadeShadowSettings ActiveCascadeSetting = ESkyCascadeShadowSettings::Off;
	private TPerPlayer<float> PerPlayerCSMScale;
	private float PreviousEditorCSMScale = -1.0;

	UFUNCTION()
	void SetLightingConfig(int Index)
	{
		FHazeLightingConfig Scenario = LightingConfigs[Index];

		// Disable the previous lighting scenario
		if(LightingConfigLast.PostProcess != nullptr) 
		{
			LightingConfigLast.PostProcess.bEnabled = true;
			LightingConfigLast.PostProcess.BlendWeight = 0;
		}
		
		for (int i = 0; i < LightingConfigLast.HazeSpheres.Num(); i++)
		{
			if (IsValid(LightingConfigLast.HazeSpheres[i]))
				LightingConfigLast.HazeSpheres[i].HazeSphereComponent.SetVisibility(false);
		}

		for (int i = 0; i < LightingConfigLast.Lights.Num(); i++)
		{
			if (IsValid(LightingConfigLast.Lights[i]))
				LightingConfigLast.Lights[i].LightComponent.SetVisibility(false);
		}
		
		LightingConfigLast = LightingConfigCurrent;
		LightingConfigCurrent = Scenario;


		SkyLight.SetIntensity(Scenario.SkyLightIntensity);
		SkyLight.SetLightColor(Scenario.LightColor);
		if(DirectionalLightEnabled)
		{
			DirectionalLight.SetIntensity(Scenario.LightIntensity);
			DirectionalLight.SetBloomScale(Scenario.LightShaftIntensity);
			DirectionalLight.SetBloomTint(FColor(
				uint8(Scenario.LightShaftTint.R * 255), 
				uint8(Scenario.LightShaftTint.G * 255), 
				uint8(Scenario.LightShaftTint.B * 255), 
				uint8(Scenario.LightShaftTint.A * 255)));
		}

		SetFogParameters(Scenario.Fog);

		if(Scenario.PostProcess != nullptr)
		{
			Scenario.PostProcess.bEnabled = true;
			Scenario.PostProcess.BlendWeight = 100;
		}
			
		for (int i = 0; i < LightingConfigLast.HazeSpheres.Num(); i++)
		{
			if (IsValid(LightingConfigLast.HazeSpheres[i]))
				LightingConfigLast.HazeSpheres[i].HazeSphereComponent.SetVisibility(true);
		}

		for (int i = 0; i < LightingConfigLast.Lights.Num(); i++)
		{
			if (IsValid(LightingConfigLast.Lights[i]))
				LightingConfigLast.Lights[i].LightComponent.SetVisibility(true);
		}
		if(Scenario.SkyTexture != nullptr)
		{
			SkyMaterialDynamic.SetTextureParameterValue(n"SkyTexture", Scenario.SkyTexture);
			SkyMaterialDynamic.SetTextureParameterValue(n"SkyTextureAlternate", Scenario.SkyTexture);
		}
	}

	UPROPERTY()
	float LightingConfigBlendTime;
	UPROPERTY()
	float LightingConfigBlendTimeMax;

	UFUNCTION()
	void SetLightingConfigBlend(int Index, float BlendTime)
	{
		LightingConfigBlendTime = BlendTime;
		LightingConfigBlendTimeMax = BlendTime;

		LightingConfigLast = LightingConfigCurrent;
		if(Index >= 0)
			LightingConfigCurrent = LightingConfigs[Index];
		else
			LightingConfigCurrent = LightingConfigOriginal;
		
		for (int i = 0; i < LightingConfigLast.HazeSpheres.Num(); i++)
		{
			if(LightingConfigLast.HazeSpheres[i] == nullptr)
			{
#if EDITOR
				PrintWarning(f"AGameSky::SetLightingConfigBlend(): Previous LightingConfig had a nullptr HazeSphere. Either remove the empty element on BP_Sky or assign it to a valid HazeSphere!");
#endif
				continue;
			}

			LightingConfigLast.HazeSpheres[i].HazeSphereComponent.SetVisibility(false);
		}

		for (int i = 0; i < LightingConfigCurrent.HazeSpheres.Num(); i++)
		{
			if(LightingConfigCurrent.HazeSpheres[i] == nullptr)
			{
#if EDITOR
				PrintWarning(f"AGameSky::SetLightingConfigBlend(): New LightingConfig has a nullptr HazeSphere. Either remove the empty element on BP_Sky or assign it to a valid HazeSphere!");
#endif
				continue;
			}

			LightingConfigCurrent.HazeSpheres[i].HazeSphereComponent.SetVisibility(true);
		}
	}

	void Init()
	{
		LightingConfigCurrent.SkyLightIntensity = SkyLightIntensity;
		LightingConfigCurrent.LightColor = LightColor;
		LightingConfigCurrent.LightIntensity = LightIntensity;
		LightingConfigCurrent.SkyTexture = SkyTexture;
		LightingConfigCurrent.Fog = Fog;
		LightingConfigCurrent.PostProcess = nullptr;
		LightingConfigCurrent.HazeSpheres = TArray<AHazeSphere>();
		LightingConfigCurrent.Lights = TArray<ALight>();
		LightingConfigCurrent.HDRIntensity = HDRIntensity;
		LightingConfigCurrent.SkyTint = SkyTint;
		LightingConfigOriginal = LightingConfigCurrent;

		for (int i = 0; i < LightingConfigs.Num(); i++)
		{
			if(LightingConfigs[i].PostProcess != nullptr)
			{
				LightingConfigs[i].PostProcess.bEnabled = true;
				LightingConfigs[i].PostProcess.BlendWeight = 0;
			}
		}
		if(LightingConfigPreview >= 0 && LightingConfigPreview < LightingConfigs.Num())
		{
			if(LightingConfigs[LightingConfigPreview].PostProcess != nullptr)
			{
				LightingConfigs[LightingConfigPreview].PostProcess.bEnabled = true;
				LightingConfigs[LightingConfigPreview].PostProcess.BlendWeight = 100;
			}
		}

		ExponentialHeightFog.SetVisibility(FogEnabled);
		if(FogEnabled)
		{
			if(LightingConfigPreview >= 0 && LightingConfigPreview < LightingConfigs.Num())
			{
				SetFogParameters(LightingConfigs[LightingConfigPreview].Fog);
			}
			else
			{
				if(PreviewAlternateLighting)
				{
					SetFogParameters(AlternateFog);
				}
				else
				{
					SetFogParameters(Fog);
				}
			}
		}
		
		SkydomeSun.SetVisibility(SkydomeSunEnabled);
		if(SkydomeSunEnabled)
		{
			SkydomeSun.SetMaterial(0, SkydomeSunMaterial);
			SunMaterialDynamic = SkydomeSun.CreateDynamicMaterialInstance(0);
			SunMaterialDynamic.SetScalarParameterValue(n"SunFlareIntensity", SunFlareIntensity);
			SunMaterialDynamic.SetVectorParameterValue(n"SunTint", SunTint);
		}

		Skydome.SetVisibility(SkydomeEnabled);
		SkydomeLowerHemisphere.SetVisibility(SkydomeEnabled && LowerHemisphereMesh);
		if(SkydomeEnabled)
		{
			Skydome.SetMaterial(0, SkyMaterial);
			SkyMaterialDynamic = Skydome.CreateDynamicMaterialInstance(0);

			SkyMaterialDynamic.SetScalarParameterValue(n"SkyTextureIs360", SkyTextureIs360 ? 1 : 0);
			SkyMaterialDynamic.SetScalarParameterValue(n"HDRIntensity", HDRIntensity);
			SkyMaterialDynamic.SetScalarParameterValue(n"WindStrength", WindStrength * 0.2);

			SkyMaterialDynamic.SetTextureParameterValue(n"SkyTexture", SkyTexture);
			if(SkyTextureAlternate != nullptr)
				SkyMaterialDynamic.SetTextureParameterValue(n"SkyTextureAlternate", SkyTextureAlternate);
			else
				SkyMaterialDynamic.SetTextureParameterValue(n"SkyTextureAlternate", SkyTexture);
			
			SkyMaterialDynamic.SetScalarParameterValue(n"TextureIsHDR", 0);
			if(SkyTexture != nullptr && SkyTexture.Class == UTextureCube)
			{
				SkyMaterialDynamic.SetScalarParameterValue(n"TextureIsHDR", 1);
				
				SkyMaterialDynamic.SetTextureParameterValue(n"SkyTextureCube", SkyTexture);
				if(SkyTextureAlternate != nullptr)
					SkyMaterialDynamic.SetTextureParameterValue(n"SkyTextureCubeAlternate", SkyTextureAlternate);
				else
					SkyMaterialDynamic.SetTextureParameterValue(n"SkyTextureCubeAlternate", SkyTexture);
			}

			if(LightingConfigPreview >= 0 && LightingConfigPreview < LightingConfigs.Num())
			{
				SkyMaterialDynamic.SetScalarParameterValue(n"AlternateBlend", 0); // TODO
			}
			else
			{
				if(PreviewAlternateLighting)
				{
					SkyMaterialDynamic.SetScalarParameterValue(n"AlternateBlend", 1);
				}
				else
				{
					SkyMaterialDynamic.SetScalarParameterValue(n"AlternateBlend", 0);
				}
			}

			SkyMaterialDynamic.SetVectorParameterValue(n"SkyTint", SkyTint);
			SkyMaterialDynamic.SetVectorParameterValue(n"SkyDirectionTint", SkyDirectionTint);
			SkyMaterialDynamic.SetVectorParameterValue(n"LightDirection", FLinearColor(GetActorRotation().ForwardVector.X, GetActorRotation().ForwardVector.Y, GetActorRotation().ForwardVector.Z, 0));
			SkyMaterialDynamic.SetVectorParameterValue(n"WindDirection", FLinearColor(WindDirection.GetSafeNormal()));
			SkyMaterialDynamic.SetScalarParameterValue(n"WhitespaceBlend", WhitespaceBlend);
			SkyMaterialDynamic.SetScalarParameterValue(n"Glitch_Tiling", WhitespaceTiling * 8);
			SkyMaterialDynamic.SetScalarParameterValue(n"WhitespaceBorderWidth", WhitespaceBorderWidth);
			
			if(LowerHemisphereMesh)
			{
				if(bLowerHemisphereMeshUseSkyMaterial)
				{
					SkydomeLowerHemisphere.SetMaterial(0, SkyMaterialDynamic);
				}
				else
				{
					SkydomeLowerHemisphere.SetMaterial(0, SkyMaterial);
					SkydomeLowerHemisphereMaterialDynamic = SkydomeLowerHemisphere.CreateDynamicMaterialInstance(0);
					
				if(LightingConfigPreview >= 0 && LightingConfigPreview < LightingConfigs.Num())
				{
					SkyMaterialDynamic.SetScalarParameterValue(n"AlternateBlend", 0); // TODO
				}
				else
				{
					if(PreviewAlternateLighting)
					{
						SkydomeLowerHemisphereMaterialDynamic.SetScalarParameterValue(n"AlternateBlend", 1);
					}
					else
					{
						SkydomeLowerHemisphereMaterialDynamic.SetScalarParameterValue(n"AlternateBlend", 0);
					}
				}

					SkydomeLowerHemisphereMaterialDynamic.SetVectorParameterValue(n"EmissiveColor", LowerHemisphereColor);
					SkydomeLowerHemisphereMaterialDynamic.SetScalarParameterValue(n"WhitespaceBlend", WhitespaceBlend);
					SkydomeLowerHemisphereMaterialDynamic.SetScalarParameterValue(n"Glitch_Tiling", WhitespaceTiling * 8);
					SkydomeLowerHemisphereMaterialDynamic.SetScalarParameterValue(n"WhitespaceBorderWidth", WhitespaceBorderWidth);
					
					SkydomeLowerHemisphereMaterialDynamic.SetScalarParameterValue(n"Underside", 1);
					SkydomeLowerHemisphereMaterialDynamic.SetScalarParameterValue(n"SkyTextureIs360", SkyTextureIs360 ? 1 : 0);
					SkydomeLowerHemisphereMaterialDynamic.SetScalarParameterValue(n"HDRIntensity", HDRIntensity);
					SkydomeLowerHemisphereMaterialDynamic.SetScalarParameterValue(n"WindStrength", WindStrength * 0.2);

					SkydomeLowerHemisphereMaterialDynamic.SetTextureParameterValue(n"SkyTexture", SkyTexture);
					if(SkyTextureAlternate != nullptr)
						SkydomeLowerHemisphereMaterialDynamic.SetTextureParameterValue(n"SkyTextureAlternate", SkyTextureAlternate);
					else
						SkydomeLowerHemisphereMaterialDynamic.SetTextureParameterValue(n"SkyTextureAlternate", SkyTexture);
					
					SkydomeLowerHemisphereMaterialDynamic.SetVectorParameterValue(n"SkyTint", SkyTint);
					SkydomeLowerHemisphereMaterialDynamic.SetVectorParameterValue(n"SkyDirectionTint", SkyDirectionTint);
					SkydomeLowerHemisphereMaterialDynamic.SetVectorParameterValue(n"LightDirection", FLinearColor(GetActorRotation().ForwardVector.X, GetActorRotation().ForwardVector.Y, GetActorRotation().ForwardVector.Z, 0));
					SkydomeLowerHemisphereMaterialDynamic.SetVectorParameterValue(n"WindDirection", FLinearColor(WindDirection.GetSafeNormal()));
				}
			}
		}
		
		if(WindParameters != nullptr)
		{
			Material::SetScalarParameterValue(WindParameters, n"WindStrength", WindStrength);
			Material::SetScalarParameterValue(WindParameters, n"WindGusts", WindGusts);
			Material::SetVectorParameterValue(WindParameters, n"WindDirection", FLinearColor(WindDirection.GetSafeNormal()));
		}
		
		if(GlobalParameters != nullptr)
		{
			Material::SetVectorParameterValue(GlobalParameters, n"SunColor", LightTint);
			Material::SetVectorParameterValue(GlobalParameters, n"AmbientColor", LightColor);
			Material::SetVectorParameterValue(GlobalParameters, n"SunDirection", FLinearColor(GetActorForwardVector()));
			Material::SetScalarParameterValue(GlobalParameters, n"OceanOpacityDepth", OceanOpacityDepth);
			Material::SetScalarParameterValue(GlobalParameters, n"OceanMinOpacity", OceanMinOpacity);
			Material::SetScalarParameterValue(GlobalParameters, n"OceanMaxOpacity", OceanMaxOpacity);
			Material::SetVectorParameterValue(GlobalParameters, n"BPSkyPosition", FLinearColor(GetActorLocation()));
			Material::SetScalarParameterValue(GlobalParameters, n"BushWobblePlayerSizeMultiplier", BushWobblePlayerSizeMultiplier);
		}
	}


#if EDITORONLY_DATA
	// Deprecated
	UPROPERTY(EditAnywhere, Meta = (EditCodition = "false", EditConditionHides))
	float DynamicShadowDistanceStationaryLight = 0.0;
	
    UFUNCTION(BlueprintOverride)
    void ConstructionScript()
    {
		//GlobalRainComponent.ConstructionScript();
		if (Editor::IsCooking())
			SkyLight.SetVisibility(false);

		float Arrowscale = 8;
		// Make the arrow larger when rotating the actor.
		if(LastRotation != GetActorRotation() && LastRotation != FRotator::ZeroRotator)
			Arrowscale = 80;
		LastRotation = GetActorRotation();

		Arrow.SetRelativeScale3D(FVector::OneVector*Arrowscale);
		Arrow.SetWorldLocation(this.GetActorLocation() - (GetActorRotation().ForwardVector * Arrowscale * 80));

		SetActorScale3D(FVector::OneVector);
		
		if(!FirstRotationSet)
		{
			FirstRotationSet = true;
			SetActorRotation(FRotator(-45.0, 25.0, 0.0));
		}

		DirectionalLight.SetVisibility(DirectionalLightEnabled);
		DirectionalLight.SetIntensity(0);
		if(DirectionalLightEnabled)
		{
			DirectionalLight.SetMobility(DirectionalLightMobility);
				
			DirectionalLight.SetWorldRotation(GetActorRotation());
			DirectionalLight.SetIntensity(LightIntensity);
			DirectionalLight.SetBloomScale(LightShaftIntensity);
			DirectionalLight.SetBloomTint(FColor(
				uint8(LightShaftTint.R * 255), 
				uint8(LightShaftTint.G * 255), 
				uint8(LightShaftTint.B * 255), 
				uint8(LightShaftTint.A * 255)));
			
			DirectionalLight.Temperature = LightTemperature;
			DirectionalLight.bUseTemperature = LightUseTemperature;
			DirectionalLight.LightColor = LightTint;
			DirectionalLight.SetIndirectLightingIntensity(IndirectLightingIntensity);
			DirectionalLight.SetEnableLightShaftBloom(true);
			DirectionalLight.ShadowResolutionScale = 2.0;
			DirectionalLight.SetShadowBias(0.25);
			DirectionalLight.CastStaticShadows = true;
			DirectionalLight.SetLightFunctionMaterial(LightMaterialFunction);

			if (DynamicShadowDistanceStationaryLight != 0.0)
			{
				SkyCascadeShadows = ESkyCascadeShadowSettings::StandardCascades;
				DynamicShadowDistanceStationaryLight = 0.0;
			}

			UpdateCascadeSettings(false);

			DirectionalLight.SetShadowAmount(ShadowAmount); // 1.0
			DirectionalLight.SetSpecularScale(SpecularScale); // 1.0
			DirectionalLight.ShadowResolutionScale = ShadowResolutionScale; // 1.0
			DirectionalLight.SetShadowBias(ShadowBias); // 0.5
			DirectionalLight.SetShadowSlopeBias(ShadowSlopeBias); // 0.5
			DirectionalLight.ShadowSharpen = ShadowSharpen; // 0
			DirectionalLight.ContactShadowLength = ContactShadowLength; // 0
			DirectionalLight.ContactShadowCastingIntensity = ContactShadowIntensity; // 0
			DirectionalLight.CastTranslucentShadows = CastTranslucentShadows; // true
			//DirectionalLight.SetbCastShadowsFromCinematicObjectsOnly(); // false
			// TODO 5.3: This was removed
			// DirectionalLight.SetAffectDynamicIndirectLighting(AffectDynamicIndirectLighting); // true


			// Lightmass
			DirectionalLight.LightSourceAngle = LightSourceAngle;
			DirectionalLight.LightmassSettings.LightSourceAngle = LightSourceAngle;
			DirectionalLight.LightmassSettings.IndirectLightingSaturation = IndirectLightingSaturation;
			DirectionalLight.LightmassSettings.ShadowExponent = ShadowExponent;
			DirectionalLight.LightmassSettings.bUseAreaShadowsForStationaryLight = bUseAreaShadowsForStationaryLight;
		}

		SkyLight.SetVisibility(SkyLightEnabled);
		if(SkyLightEnabled)
		{
			SkyLight.OcclusionMaxDistance = OcclusionMaxDistance;
			SkyLight.SetOcclusionContrast(OcclusionContrast);
			SkyLight.SetOcclusionExponent(OcclusionExponent);
			SkyLight.SetMinOcclusion(MinOcclusion);
			SkyLight.OcclusionCombineMode = OcclusionCombineMode;
			SkyLight.SetOcclusionTint(OcclusionTint);

			SkyLight.SetWorldRotation(FRotator::ZeroRotator);
			
			if(LightingConfigPreview >= 0 && LightingConfigPreview < LightingConfigs.Num())
			{
				SkyLight.SetIntensity(LightingConfigs[LightingConfigPreview].SkyLightIntensity);
				SkyLight.SetLightColor(LightingConfigs[LightingConfigPreview].LightColor);
				if(DirectionalLightEnabled)
				{
					DirectionalLight.SetIntensity(LightingConfigs[LightingConfigPreview].LightIntensity);
					DirectionalLight.SetBloomScale(LightingConfigs[LightingConfigPreview].LightShaftIntensity);
					DirectionalLight.SetBloomTint(FColor(
						uint8(LightingConfigs[LightingConfigPreview].LightShaftTint.R * 255), 
						uint8(LightingConfigs[LightingConfigPreview].LightShaftTint.G * 255), 
						uint8(LightingConfigs[LightingConfigPreview].LightShaftTint.B * 255), 
						uint8(LightingConfigs[LightingConfigPreview].LightShaftTint.A * 255)));
				}
			}
			else
			{
				if(PreviewAlternateLighting)
				{
					SkyLight.SetIntensity(AlternateSkyLightIntensity);
					SkyLight.SetLightColor(AlternateLightColor);
					if(DirectionalLightEnabled)
					{
						DirectionalLight.SetIntensity(AlternateLightIntensity);
						DirectionalLight.SetBloomScale(AlternateLightShaftIntensity);
						DirectionalLight.SetBloomTint(FColor(
							uint8(AlternateLightShaftTint.R * 255), 
							uint8(AlternateLightShaftTint.G * 255), 
							uint8(AlternateLightShaftTint.B * 255), 
							uint8(AlternateLightShaftTint.A * 255)));
					}
					
				}
				else
				{
					SkyLight.SetIntensity(SkyLightIntensity);
					SkyLight.SetLightColor(LightColor);
					if(DirectionalLightEnabled)
					{
						DirectionalLight.SetIntensity(LightIntensity);
						DirectionalLight.SetBloomScale(LightShaftIntensity);
						DirectionalLight.SetBloomTint(FColor(
							uint8(LightShaftTint.R * 255), 
							uint8(LightShaftTint.G * 255), 
							uint8(LightShaftTint.B * 255), 
							uint8(LightShaftTint.A * 255)));
					}
				}
			}
			Editor::SetSkyLightCubemapAndType(SkyLight, SLS_Cubemap);
			SkyLight.bRealTimeCapture = RealTimeCapture;
			SkyLight.SourceCubemapAngle = SourceCubemapAngle;
			SkyLight.CubemapResolution = CubemapResolution;
			SkyLight.SkyDistanceThreshold = SkyDistanceThreshold;
			SkyLight.bAffectsWorld = AffectsWorld;
			SkyLight.SetCastShadows(CastShadows);
			SkyLight.SetIndirectLightingIntensity(SkyLightIndirectLightingIntensity);
			SkyLight.SourceType = SkyLightSourceType;
			SkyLight.SetMobility(SkyLightMobility);
			SkyLight.bLowerHemisphereIsBlack = LowerHemisphereIsBlack;
			SkyLight.SetLowerHemisphereColor(LowerHemisphereColor);
		}

		if(SkydomeSunEnabled)
		{
			SkydomeSun.SetWorldRotation(GetActorRotation());
			SkydomeSun.SetWorldScale3D(FVector::OneVector * 50 * SkydomeScale);
			SkydomeSun.SetWorldLocation(GetActorLocation());
			SkydomeSun.AddLocalRotation(FRotator(-SunOffsetY, SunOffsetX, 0));
		}
		
		if(SkydomeEnabled)
		{
			Skydome.SetWorldRotation(FRotator(0, Angle, 0));
			Skydome.SetRelativeScale3D(FVector::OneVector * 50 * SkydomeScale);
			Skydome.SetWorldLocation(GetActorLocation());

			if(LowerHemisphereMesh)
			{
				SkydomeLowerHemisphere.SetWorldLocation(GetActorLocation() + FVector::UpVector * 20000);
				SkydomeLowerHemisphere.SetWorldRotation(FRotator(0, Angle, 180));
				SkydomeLowerHemisphere.SetRelativeScale3D(FVector::OneVector * 50 * SkydomeScale);

				if(!bLowerHemisphereMeshUseSkyMaterial)
				{
					SkydomeLowerHemisphere.SetWorldLocation(GetActorLocation());
				}
			}
		}

		Init();
    }
#endif

#if EDITOR
	UFUNCTION(CallInEditor, Category="Sky Ambient Light")
	void RecaptureSky()
	{
		if (SLS_Cubemap == nullptr)
		{
			FMessageDialog::Open(
				EAppMsgType::Ok,
				FText::FromString("BP_Sky does not have a SLS Cubemap configured currently.\n\nCreating a new one and prompting for a save location."),
			);
			auto NewCubemap = Cast<UTextureCube>(Editor::SaveAssetAsNewPath(
				LoadObject(nullptr, "/Game/Environment/Skies/SkyCaptures/SkyCube_Base.SkyCube_Base")
			));
			if (NewCubemap != nullptr)
			{
				SLS_Cubemap = NewCubemap;
				SkyLightSourceType = ESkyLightSourceType::SLS_SpecifiedCubemap;
			}
		}

		if (SLS_Cubemap != nullptr)
		{
			SkyLightSourceType = ESkyLightSourceType::SLS_SpecifiedCubemap;
			Editor::SetSkyLightCubemapAndType(SkyLight, SLS_Cubemap);
			Console::ExecuteConsoleCommand("Haze.TakeSkyCaptures");
		}
		
		SkyLight.RecaptureSky();
	}

#endif

	bool bBlendAlternateLightingEnabled;
	float AlternateLightingBlendTime;
	float AlternateLightingBlendValue;

    UFUNCTION(BlueprintOverride)
    void Tick(float DeltaSeconds)
	{
		if(LightingConfigBlendTime > 0)
		{
			LightingConfigBlendTime -= DeltaSeconds;
			float Blend = LightingConfigBlendTime / LightingConfigBlendTimeMax;
			if(Blend < 0)
				Blend = 0;
			Blend = 1.0 - Blend;
			
			DirectionalLight.SetIntensity(Math::Lerp(LightingConfigLast.LightIntensity, LightingConfigCurrent.LightIntensity, Blend));

			float BloomScale = Math::Lerp(LightingConfigLast.LightShaftIntensity, LightingConfigCurrent.LightShaftIntensity, Blend);
			FColor BloomTint = FColor(
				uint8(Math::Lerp(LightingConfigLast.LightShaftTint.R, LightingConfigCurrent.LightShaftTint.R, Blend) * 255), 
				uint8(Math::Lerp(LightingConfigLast.LightShaftTint.G, LightingConfigCurrent.LightShaftTint.G, Blend) * 255), 
				uint8(Math::Lerp(LightingConfigLast.LightShaftTint.B, LightingConfigCurrent.LightShaftTint.B, Blend) * 255), 
				uint8(Math::Lerp(LightingConfigLast.LightShaftTint.A, LightingConfigCurrent.LightShaftTint.A, Blend) * 255));

			DirectionalLight.SetBloomScale(BloomScale);
			DirectionalLight.SetBloomTint(BloomTint);
					
			SkyLight.SetLightColor(Math::Lerp(LightingConfigLast.LightColor, LightingConfigCurrent.LightColor, Blend));
			SkyLight.SetIntensity(Math::Lerp(LightingConfigLast.SkyLightIntensity, LightingConfigCurrent.SkyLightIntensity, Blend));
			if(SkydomeEnabled)
			{
				SkyMaterialDynamic.SetScalarParameterValue(n"HDRIntensity", Math::Lerp(LightingConfigLast.HDRIntensity, LightingConfigCurrent.HDRIntensity, Blend));
				SkyMaterialDynamic.SetVectorParameterValue(n"SkyTint", Math::Lerp(LightingConfigLast.SkyTint, LightingConfigCurrent.SkyTint, Blend));
					
				if(SkydomeLowerHemisphereMaterialDynamic != nullptr)
				{
					SkydomeLowerHemisphereMaterialDynamic.SetTextureParameterValue(n"SkyTexture", LightingConfigLast.SkyTexture);
					SkydomeLowerHemisphereMaterialDynamic.SetTextureParameterValue(n"SkyTextureAlternate", LightingConfigCurrent.SkyTexture);
					SkydomeLowerHemisphereMaterialDynamic.SetScalarParameterValue(n"AlternateBlend", Blend);
				}
				if(SkyMaterialDynamic != nullptr)
				{
					SkyMaterialDynamic.SetTextureParameterValue(n"SkyTexture", LightingConfigLast.SkyTexture);
					SkyMaterialDynamic.SetTextureParameterValue(n"SkyTextureAlternate", LightingConfigCurrent.SkyTexture);
					SkyMaterialDynamic.SetScalarParameterValue(n"AlternateBlend", Blend);
				}
			}
			FFogParameters BlendedFogParameters;
			BlendedFogParameters.Density 					= Math::Lerp(LightingConfigLast.Fog.Density 					, LightingConfigCurrent.Fog.Density 					, Blend);
			BlendedFogParameters.HeightOffset 				= Math::Lerp(LightingConfigLast.Fog.HeightOffset 				, LightingConfigCurrent.Fog.HeightOffset 				, Blend);
			BlendedFogParameters.HeightFalloff 				= Math::Lerp(LightingConfigLast.Fog.HeightFalloff 				, LightingConfigCurrent.Fog.HeightFalloff 				, Blend);
			BlendedFogParameters.MaxOpacity 				= Math::Lerp(LightingConfigLast.Fog.MaxOpacity 					, LightingConfigCurrent.Fog.MaxOpacity 					, Blend);
			BlendedFogParameters.StartDistance 				= Math::Lerp(LightingConfigLast.Fog.StartDistance 				, LightingConfigCurrent.Fog.StartDistance 				, Blend);
			BlendedFogParameters.Color 						= Math::Lerp(LightingConfigLast.Fog.Color 						, LightingConfigCurrent.Fog.Color 						, Blend);
			BlendedFogParameters.DirectionalColorEnabled 	= (Blend > 0.5) ? LightingConfigLast.Fog.DirectionalColorEnabled : LightingConfigCurrent.Fog.DirectionalColorEnabled;
			BlendedFogParameters.DirectionalColor 			= Math::Lerp(LightingConfigLast.Fog.DirectionalColor 			, LightingConfigCurrent.Fog.DirectionalColor 			, Blend);
			BlendedFogParameters.DirectionalStartDistance 	= Math::Lerp(LightingConfigLast.Fog.DirectionalStartDistance 	, LightingConfigCurrent.Fog.DirectionalStartDistance 	, Blend);
			BlendedFogParameters.DirectionalTightness 		= Math::Lerp(LightingConfigLast.Fog.DirectionalTightness 		, LightingConfigCurrent.Fog.DirectionalTightness 		, Blend);
			BlendedFogParameters.CutoffDistance 			= Math::Lerp(LightingConfigLast.Fog.CutoffDistance 				, LightingConfigCurrent.Fog.CutoffDistance 				, Blend);
			SetFogParameters(BlendedFogParameters);
			if(LightingConfigLast.PostProcess != nullptr)
			{
				LightingConfigLast.PostProcess.BlendWeight = (1.0-Blend);
				LightingConfigLast.PostProcess.bEnabled = true;
			}
			if(LightingConfigCurrent.PostProcess != nullptr)
			{
				LightingConfigCurrent.PostProcess.BlendWeight = Blend;
				LightingConfigCurrent.PostProcess.bEnabled = true;
			}
		}
		if(AlternateLightingBlendValue != 1 && AlternateLightingBlendValue != 0)
		{
			if(bBlendAlternateLightingEnabled) 
				AlternateLightingBlendValue += DeltaSeconds / AlternateLightingBlendTime;
			else
				AlternateLightingBlendValue -= DeltaSeconds / AlternateLightingBlendTime;

			if(AlternateLightingBlendValue < 0 )
				AlternateLightingBlendValue = 0;
			if(AlternateLightingBlendValue > 1 )
				AlternateLightingBlendValue = 1;
			
			if(SkydomeLowerHemisphereMaterialDynamic != nullptr)
			{
				SkydomeLowerHemisphereMaterialDynamic.SetScalarParameterValue(n"AlternateBlend", AlternateLightingBlendValue);
			}
			if(SkyMaterialDynamic != nullptr)
			{
				SkyMaterialDynamic.SetScalarParameterValue(n"AlternateBlend", AlternateLightingBlendValue);
			}

			DirectionalLight.SetIntensity(Math::Lerp(LightIntensity, AlternateLightIntensity, AlternateLightingBlendValue));
			SkyLight.SetLightColor(Math::Lerp(LightColor, AlternateLightColor, AlternateLightingBlendValue));
			SkyLight.SetIntensity(Math::Lerp(SkyLightIntensity, AlternateSkyLightIntensity, AlternateLightingBlendValue));
			FFogParameters BlendedFogParameters;
			BlendedFogParameters.Density 					= Math::Lerp(Fog.Density 					, AlternateFog.Density 						, AlternateLightingBlendValue);
			BlendedFogParameters.HeightOffset 				= Math::Lerp(Fog.HeightOffset 				, AlternateFog.HeightOffset 				, AlternateLightingBlendValue);
			BlendedFogParameters.HeightFalloff 				= Math::Lerp(Fog.HeightFalloff 				, AlternateFog.HeightFalloff 				, AlternateLightingBlendValue);
			BlendedFogParameters.MaxOpacity 				= Math::Lerp(Fog.MaxOpacity 				, AlternateFog.MaxOpacity 					, AlternateLightingBlendValue);
			BlendedFogParameters.StartDistance 				= Math::Lerp(Fog.StartDistance 				, AlternateFog.StartDistance 				, AlternateLightingBlendValue);
			BlendedFogParameters.Color 						= Math::Lerp(Fog.Color 						, AlternateFog.Color 						, AlternateLightingBlendValue);
			BlendedFogParameters.DirectionalColorEnabled 	= (AlternateLightingBlendValue > 0.5) ? Fog.DirectionalColorEnabled : AlternateFog.DirectionalColorEnabled;
			BlendedFogParameters.DirectionalColor 			= Math::Lerp(Fog.DirectionalColor 			, AlternateFog.DirectionalColor 			, AlternateLightingBlendValue);
			BlendedFogParameters.DirectionalStartDistance 	= Math::Lerp(Fog.DirectionalStartDistance 	, AlternateFog.DirectionalStartDistance 	, AlternateLightingBlendValue);
			BlendedFogParameters.DirectionalTightness 		= Math::Lerp(Fog.DirectionalTightness 		, AlternateFog.DirectionalTightness 		, AlternateLightingBlendValue);
			BlendedFogParameters.CutoffDistance 			= Math::Lerp(Fog.CutoffDistance 			, AlternateFog.CutoffDistance 				, AlternateLightingBlendValue);
			SetFogParameters(BlendedFogParameters);
		}
		else
		{
			//SkyLight.bRealTimeCapture = false;
		}

		if(SkydomeEnabled && (SkyMaterialDynamic != nullptr))
		{
			SkyMaterialDynamic.SetScalarParameterValue(n"WhitespaceBlend", WhitespaceBlend);
			SkyMaterialDynamic.SetScalarParameterValue(n"Glitch_Tiling", WhitespaceTiling * 8);
			SkyMaterialDynamic.SetScalarParameterValue(n"WhitespaceBorderWidth", WhitespaceBorderWidth);
		}

		if(WindParameters != nullptr)
		{
			WindStrengthCurrent = Math::FInterpTo(WindStrengthCurrent, WindStrength, DeltaSeconds, 1.0);
			WindGustsCurrent = Math::FInterpTo(WindGustsCurrent, WindStrength, DeltaSeconds, 1.0);
			Material::SetScalarParameterValue(WindParameters, n"WindStrength", WindStrengthCurrent);
			Material::SetScalarParameterValue(WindParameters, n"WindGusts", WindGustsCurrent);
			Material::SetVectorParameterValue(WindParameters, n"WindDirection", FLinearColor(WindDirection.GetSafeNormal()));
		}

		if (SkydomeEnabled && bUseIntensityOverride)
			SkyMaterialDynamic.SetScalarParameterValue(n"HDRIntensity", HDRIntensity);
    }

    UFUNCTION(BlueprintOverride)
	void BeginPlay()
    {
		// The skylight is hidden until the level we're in is activated
		//   This would normally be dealt with by the rendering code, but we're working around not having to change the engine right now
		Level.OnLevelActivated.AddUFunction(this, n"OnLevelActivated");
		Level.OnLevelDeactivated.AddUFunction(this, n"OnLevelDeactivated");

		if (Progress::HasActivatedAnyProgressPoint()
#if EDITOR
			|| Progress::GetActiveLevels().Num() != 0
#endif
		)
		{
			SkyLight.SetVisibility(false);
		}

		Init();

		if(GlobalParameters != nullptr)
		{
			Material::SetScalarParameterValue(GlobalParameters, n"Playing", 1.0);
		}
		// Apply cascade settings here, so they can depend on the platform settings
		UpdateCascadeSettings();
    }

	UFUNCTION()
	void SetDirectionalLightEnabled(bool bEnabled)
	{
		DirectionalLight.SetVisibility(bEnabled);
	}

	UFUNCTION()
	void SetAlternateLightingEnabledWithBlend(bool bEnabled, float BlendTime)
	{
		if(bBlendAlternateLightingEnabled != bEnabled)
		{
			bBlendAlternateLightingEnabled = bEnabled;
			AlternateLightingBlendTime = BlendTime;
			AlternateLightingBlendValue = bEnabled ? 0.0001 : 0.999;
		}
	}

	private void SetFogParameters(FFogParameters FogParameters)
	{
		ExponentialHeightFog.SetWorldRotation(FRotator::ZeroRotator);
		ExponentialHeightFog.SetWorldLocation(GetActorLocation() + FVector(0,0, FogParameters.HeightOffset));
		ExponentialHeightFog.SetFogDensity(FogParameters.Density);
		ExponentialHeightFog.SetFogHeightFalloff(FogParameters.HeightFalloff );
		ExponentialHeightFog.SetFogMaxOpacity(FogParameters.MaxOpacity);
		ExponentialHeightFog.SetStartDistance(FogParameters.StartDistance);
		ExponentialHeightFog.SetFogInscatteringColor(FogParameters.Color);
		ExponentialHeightFog.SetFogCutoffDistance(FogParameters.CutoffDistance);
		ExponentialHeightFog.VolumetricFog = false;
		if(FogParameters.DirectionalColorEnabled)
		{
			ExponentialHeightFog.SetDirectionalInscatteringColor(FogParameters.DirectionalColor);
			ExponentialHeightFog.SetDirectionalInscatteringStartDistance(FogParameters.DirectionalStartDistance);
			ExponentialHeightFog.SetDirectionalInscatteringExponent(FogParameters.DirectionalTightness);
		}
		else
		{
			ExponentialHeightFog.SetDirectionalInscatteringColor(FLinearColor(0.25, 0.25, 0.125, 1.0));
			ExponentialHeightFog.SetDirectionalInscatteringStartDistance(10000.0);
			ExponentialHeightFog.SetDirectionalInscatteringExponent(4.0);
		}
	}

	UFUNCTION()
	void SetAlternateLightingEnabled(bool bEnabled)
	{
		bBlendAlternateLightingEnabled = bEnabled;
		AlternateLightingBlendTime = 1.0;
		AlternateLightingBlendValue = bEnabled ? 1.0 : 0.0;

		if(bEnabled)
		{
			SkyLight.SetIntensity(AlternateSkyLightIntensity);
			SkyLight.SetLightColor(AlternateLightColor);
			if(FogEnabled)
				SetFogParameters(AlternateFog);
			if(DirectionalLightEnabled)
				DirectionalLight.SetIntensity(AlternateLightIntensity);
		}
		else
		{
			SkyLight.SetIntensity(SkyLightIntensity);
			SkyLight.SetLightColor(LightColor);
			if(FogEnabled)
				SetFogParameters(Fog);
			if(DirectionalLightEnabled)
				DirectionalLight.SetIntensity(LightIntensity);
		}
	}

	UFUNCTION()
	private void OnLevelActivated()
	{
		if(SkyLightEnabled)
		{
			SkyLight.SetVisibility(true);
		}
	}

	UFUNCTION()
	private void OnLevelDeactivated()
	{
		SkyLight.SetVisibility(false);
	}

	void UpdateCascadeSettings(bool bUseViewLocation = true)
	{
		int OptionQuality = CVar_GameSkyShadowCascadeQuality.GetInt();
#if EDITOR
		if (CVar_PreviewGameSkyCascadesInEditor.GetInt() == 0)
			OptionQuality = 0;
#endif

		// If the base cascade configuration has changed, update it
		if (OptionQuality != ActiveCascadeQuality || ActiveCascadeSetting != SkyCascadeShadows)
		{
			ActiveCascadeQuality = OptionQuality;
			ActiveCascadeSetting = SkyCascadeShadows;

			if (DirectionalLightEnabled
				&& ActiveCascadeQuality != 0
				&& SkyCascadeShadows != ESkyCascadeShadowSettings::Off
			)
			{
				if (SkyCascadeShadows == ESkyCascadeShadowSettings::StandardCascades)
				{
					if (ActiveCascadeQuality >= 3)
					{
						DirectionalLight.SetDynamicShadowDistanceStationaryLight(8000.0);
						DirectionalLight.SetDynamicShadowCascades(3);
					}
					else if (ActiveCascadeQuality >= 2)
					{
						DirectionalLight.SetDynamicShadowDistanceStationaryLight(2600.0);
						DirectionalLight.SetDynamicShadowCascades(1);
					}
					else
					{
						DirectionalLight.SetDynamicShadowDistanceStationaryLight(2600.0);
						DirectionalLight.SetDynamicShadowCascades(1);
					}
				}
				else if (SkyCascadeShadows == ESkyCascadeShadowSettings::StandardCascades_NotOnMedium)
				{
					if (ActiveCascadeQuality >= 3)
					{
						DirectionalLight.SetDynamicShadowDistanceStationaryLight(8000.0);
						DirectionalLight.SetDynamicShadowCascades(3);
					}
					else if (ActiveCascadeQuality >= 2)
					{
						DirectionalLight.SetDynamicShadowDistanceStationaryLight(2600.0);
						DirectionalLight.SetDynamicShadowCascades(1);
					}
					else
					{
						DirectionalLight.SetDynamicShadowDistanceStationaryLight(0);
						DirectionalLight.SetDynamicShadowCascades(0);
					}
				}
				else if (SkyCascadeShadows == ESkyCascadeShadowSettings::CanopyCascadesOnHighOnly)
				{
					if (ActiveCascadeQuality >= 3)
					{
						DirectionalLight.SetDynamicShadowDistanceStationaryLight(8000.0);
						DirectionalLight.SetDynamicShadowCascades(3);
					}
					else if (ActiveCascadeQuality >= 2)
					{
						DirectionalLight.SetDynamicShadowDistanceStationaryLight(5200.0);
						DirectionalLight.SetDynamicShadowCascades(1);
					}
					else
					{
						DirectionalLight.SetDynamicShadowDistanceStationaryLight(0);
						DirectionalLight.SetDynamicShadowCascades(0);
					}
				}
				else if (SkyCascadeShadows == ESkyCascadeShadowSettings::StandardCascades_OnlyOnUltra)
				{
					if (ActiveCascadeQuality >= 3)
					{
						DirectionalLight.SetDynamicShadowDistanceStationaryLight(8000.0);
						DirectionalLight.SetDynamicShadowCascades(3);
					}
					else
					{
						DirectionalLight.SetDynamicShadowDistanceStationaryLight(0);
						DirectionalLight.SetDynamicShadowCascades(0);
					}
				}
				else if (SkyCascadeShadows == ESkyCascadeShadowSettings::CutsceneQuality)
				{
					if (ActiveCascadeQuality >= 2)
					{
						DirectionalLight.SetDynamicShadowDistanceStationaryLight(12000.0);
						DirectionalLight.SetDynamicShadowCascades(3);
					}
					else
					{
						DirectionalLight.SetDynamicShadowDistanceStationaryLight(2600.0);
						DirectionalLight.SetDynamicShadowCascades(1);
					}
				}
			}
			else
			{
				DirectionalLight.SetDynamicShadowDistanceStationaryLight(0);
				DirectionalLight.SetDynamicShadowCascades(0);
			}
		}

		if (bUseViewLocation)
		{
			if (World.IsGameWorld())
			{
				// Each player also has its own scalar for CSM size, we use this mainly for
				// if the camera gets zoomed out compared to where the player is.
				bool bBothPlayersDisableDirectionalLight = true;
				if (Game::GetPlayers().Num() != 0)
				{
					for (auto Player : Game::Players)
					{
						float PreviousScale = PerPlayerCSMScale[Player];
						float WantedScale = 1.0;
						bool bSnapScale = false;
						if (PreviousScale == 0)
							bSnapScale = true;

						bool bDisableCascades = false;
						bool bDisableDirectionalLight = false;
						AIndoorSkyLightingVolume::GetIndoorSkyLightingSettings(
							Player.ViewLocation,
							Player.ActorLocation,
							bDisableCascades, bDisableDirectionalLight);

						if (!bDisableDirectionalLight)
							bBothPlayersDisableDirectionalLight = false;

						// Check if the camera is inside any indoor volumes
						if (bDisableCascades)
						{
							WantedScale = 0.0;
							bSnapScale = true;
						}
						else
						{
							if (Player.bIsControlledByCutscene && SceneView::IsPendingFullscreen())
							{
								// During cutscenes we don't mess with the CSM distance
								WantedScale = 1.0;
							}
							else
							{
								// If the distance between the camera and the player is too high,
								// increase the CSM distance so it doesn't look as weird being faded out
								float PlayerCameraDistance = Math::RoundToFloat(Player.ActorCenterLocation.Distance(Player.ViewLocation) / 10.0) * 10.0;

								WantedScale = Math::GetMappedRangeValueClamped(
									FVector2D(500.0, 1000.0),
									FVector2D(1.0, 1.5),
									Math::RoundToFloat(PlayerCameraDistance)
								);
							}
						}

						if (PreviousScale != WantedScale)
						{
							if (!bSnapScale)
								WantedScale = Math::FInterpConstantTo(PreviousScale, WantedScale, Time::UndilatedWorldDeltaSeconds, 2.0);
							PerPlayerCSMScale[Player] = WantedScale;

							int ViewIndex;
							if (Player.IsMio())
								ViewIndex = 0;
							else
								ViewIndex = 1;

							SceneView::SetCSMDistanceScaleForView(ViewIndex, WantedScale);
						}
					}
				}
				else
				{
					// If there are no players, this is the main menu and we should take the views from menu camera users
					for (AMenuCameraUser CameraUser : TListedActors<AMenuCameraUser>())
					{
						if (!CameraUser.IsViewPointOnScreen())
							continue;

						bool bDisableCascades = false;
						bool bDisableDirectionalLight = false;
						AIndoorSkyLightingVolume::GetIndoorSkyLightingSettings(
							CameraUser.UserComp.ViewLocation,
							CameraUser.UserComp.ViewLocation,
							bDisableCascades, bDisableDirectionalLight);

						if (!bDisableDirectionalLight)
							bBothPlayersDisableDirectionalLight = false;
					}
				}

				if (DirectionalLightEnabled)
				{
					if (bBothPlayersDisableDirectionalLight && DirectionalLight.CastShadows)
					{
						DirectionalLight.SetCastShadows(false);
						DirectionalLight.SetVisibility(false);
					}
					else if (!bBothPlayersDisableDirectionalLight && !DirectionalLight.CastShadows)
					{
						DirectionalLight.SetCastShadows(true);
						DirectionalLight.SetVisibility(true);
					}
				}
			}
			else
			{
#if EDITOR
				float WantedScale = 1.0;
				bool bDisableCascades = false;
				bool bDisableDirectionalLight = false;
				AIndoorSkyLightingVolume::GetIndoorSkyLightingSettings(
					Editor::EditorViewLocation,
					Editor::EditorViewLocation,
					bDisableCascades, bDisableDirectionalLight);

				if (bDisableCascades)
					WantedScale = 0.0;

				if (WantedScale != PreviousEditorCSMScale)
				{
					SceneView::SetCSMDistanceScaleForView(-1, WantedScale);
					PreviousEditorCSMScale = WantedScale;
				}
#endif
			}
		}
	}

	void TickInGameAndEditor()
	{
		if (SkydomeEnabled && (SkyMaterialDynamic != nullptr))
		{
			SkyMaterialDynamic.SetScalarParameterValue(n"WhitespaceBlend", WhitespaceBlend);
			SkyMaterialDynamic.SetScalarParameterValue(n"Glitch_Tiling", WhitespaceTiling * 8);
			SkyMaterialDynamic.SetScalarParameterValue(n"WhitespaceBorderWidth", WhitespaceBorderWidth);
		}

		if(WindParameters != nullptr)
		{
			Material::SetScalarParameterValue(WindParameters, n"WindStrength", WindStrength);
			Material::SetScalarParameterValue(WindParameters, n"WindGusts", WindGusts);
		}

		UpdateCascadeSettings();
	}
}

// Component to make the sky update in sequencer
class UGameSkyTickInEditorComponent : USceneComponent
{
	default PrimaryComponentTick.TickGroup = ETickingGroup::TG_PostPhysics;
	default bTickInEditor = true;

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		Cast<AGameSky>(Owner).TickInGameAndEditor();
	}
};

