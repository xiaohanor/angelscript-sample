UCLASS(Abstract)
class ASequencerGlobalPostProcess : AHazePostProcessVolume 
{
	default bUnbound = true;

	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, ShowOnActor)
	USequencerGlobalPostProcessComponent SequencerGlobalPostProcessComponent;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		Init();

		auto PostProcessingComponentMio = Game::Mio.GetComponentByClass(UPostProcessingComponent);
		auto PostProcessingComponentZoe = Game::Mio.GetComponentByClass(UPostProcessingComponent);

		PostProcessingComponentMio.SetPostProcessEnabled(false);
		PostProcessingComponentZoe.SetPostProcessEnabled(false);
	}

	UFUNCTION(BlueprintOverride)
	void EndPlay(EEndPlayReason EndPlayReason)
	{
		auto PostProcessingComponentMio = Game::Mio.GetComponentByClass(UPostProcessingComponent);
		auto PostProcessingComponentZoe = Game::Mio.GetComponentByClass(UPostProcessingComponent);
		PostProcessingComponentMio.SetPostProcessEnabled(true);
		PostProcessingComponentZoe.SetPostProcessEnabled(true);
	}

	UPROPERTY(EditAnywhere)
	UMaterialInterface PostProcessMaterialLoadingScreen;

	UPROPERTY(EditAnywhere)
	UMaterialInterface PostProcessMaterial;
	
	UPROPERTY(NotEditable)
	UMaterialInstanceDynamic PostProcessMaterialDynamic;

	// Distance in world units from the camera to the whitespace start.
	UPROPERTY(EditAnywhere, Interp)
	float WhitespaceCameraBlend = 0.0;

	// Distance in world units from the camera to the whitespace start.
	UPROPERTY(EditAnywhere, Interp)
	float WhitespaceBlend = -1.0;
	
	UPROPERTY(EditAnywhere, Interp)
	float BorderWidth = 200.0;

	UPROPERTY(EditAnywhere, Interp)
	float Tiling = 1.0;
	
	UPROPERTY(EditAnywhere, Interp)
	float NoiseTiling = 1.0;
	
	UPROPERTY(EditAnywhere, Interp)
	float NoiseSpeed = 1.0;

	UPROPERTY(EditAnywhere, Interp)
	float NoiseStrength = 1.0;

	UPROPERTY(EditAnywhere, Interp)
	float LoadingScreenBlend = 0.0;

	UPROPERTY(EditAnywhere, Interp)
	bool SeparateLoadingScreen = false;

	// Called by USequencerGlobalPostProcessComponent
	void TickInEditor()
	{
#if EDITOR
		const AHazeCinematicCameraActor CameraActor = Sequencer::GetSequencerPreviewedCamera();
		if (CameraActor != nullptr)
		{
			
		}
#endif

		if (PostProcessMaterialDynamic != nullptr)
		{
			PostProcessMaterialDynamic.SetScalarParameterValue(n"LoadingScreenData_WhitespaceRealTime", 						Time::RealTimeSeconds);
			PostProcessMaterialDynamic.SetScalarParameterValue(n"whitespaceData_Radius", 										WhitespaceBlend);
			PostProcessMaterialDynamic.SetScalarParameterValue(n"whitespaceData_BorderWidth", 									BorderWidth);
			PostProcessMaterialDynamic.SetScalarParameterValue(n"whitespaceData_Tiling", 										Tiling);
			PostProcessMaterialDynamic.SetScalarParameterValue(n"whitespaceData_NoiseTiling", 									NoiseTiling);
			PostProcessMaterialDynamic.SetScalarParameterValue(n"whitespaceData_NoiseStrength", 								NoiseStrength);
			PostProcessMaterialDynamic.SetScalarParameterValue(n"whitespaceData_NoiseSpeed", 									NoiseSpeed);
			PostProcessMaterialDynamic.SetVectorParameterValue(n"whitespaceData_Center", 										FLinearColor(GetActorLocation()));
			PostProcessMaterialDynamic.SetScalarParameterValue(n"whitespaceData_SeparateLoadingScreen", 						SeparateLoadingScreen ? 1 : 0);
			PostProcessMaterialDynamic.SetScalarParameterValue(n"loadingScreenData_Blend", 										LoadingScreenBlend);
			PostProcessMaterialDynamic.SetScalarParameterValue(n"loadingScreenData_CameraBlend", 								WhitespaceCameraBlend);
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

			FWeightedBlendable Blendable2;
			Blendable2.Object = PostProcessMaterialLoadingScreen;
			Blendable2.Weight = 1.0;

			Settings.WeightedBlendables.Array.Empty();
			Settings.WeightedBlendables.Array.Add(Blendable);
			Settings.WeightedBlendables.Array.Add(Blendable2);

			Settings.AmbientCubemapIntensity = 0;
		}
	}

	UFUNCTION(BlueprintOverride)
	void ConstructionScript()
	{
		Super::ConstructionScript();
		Init();
	}
}

class USequencerGlobalPostProcessComponent : USceneComponent
{
	default bTickInEditor = true;
	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		auto SequencerGlobalPostProcess = Cast<ASequencerGlobalPostProcess>(Owner);
		SequencerGlobalPostProcess.TickInEditor();
	}

};

