
class UGlobalRainComponent : UActorComponent
{
#if EDITOR
    USceneCaptureComponent2D RainMaskSceneCaptureComponent;
#endif
	
	UPROPERTY(EditAnywhere, Category="Rain")
	bool bRainEnabed = false;

	UPROPERTY(EditAnywhere, Category="Rain")
	float RainMaskSize = 200000.0;

	UPROPERTY(EditAnywhere, Category="Rain")
	float Tiling = 0.05;
	UPROPERTY(EditAnywhere, Category="Rain")
	float Strength = 0.01;
	UPROPERTY(EditAnywhere, Category="Rain")
	float Speed = 100.0;
	UPROPERTY(EditAnywhere, Category="Rain")
	float Darkening = 1.0;

	UPROPERTY(Category="Rain")
	UMaterialInterface PackRainMaterial;

	UPROPERTY(Category="Rain")
	UMaterialInterface UnpackRainMaterial;

	UPROPERTY(EditAnywhere, Category="Rain")
	UTexture2D Target;
	
	UPROPERTY(EditAnywhere, Category="Rain")
	UTexture2D WhiteTexture;
	
	UPROPERTY()
	UMaterialParameterCollection GlobalParameters;

	UPROPERTY()
	UMaterialInterface SetColorMaterial;
	UMaterialInstanceDynamic SetColorMaterialDynamic;

	default bTickInEditor = true;

	UPROPERTY(EditAnywhere, Category="Rain")
	float HeightOffset = 30000;

	UPROPERTY(VisibleAnywhere, Transient)
	UTextureRenderTarget2D RainMaskRenderTarget;

#if EDITOR
	UFUNCTION(BlueprintOverride)
	void OnComponentModifiedInEditor()
	{
		ApplyRainMask();
	}
#endif

	UFUNCTION(CallInEditor, Category="Rain")
	void CaptureRainMask()
	{
		#if EDITOR
		CreateRainMaskRenderTarget();
		InitCaptureComponent();
		RainMaskSceneCaptureComponent.CaptureScene();
		
		UTextureRenderTarget2D TempTexture = Rendering::CreateRenderTarget2D(2048, 2048, ETextureRenderTargetFormat::RTF_RGBA8, FLinearColor(0, 0, 0, 0));
		
		UMaterialInstanceDynamic PackRainMaterialDynamic = Material::CreateDynamicMaterialInstance(this, PackRainMaterial);
		PackRainMaterialDynamic.SetTextureParameterValue(n"InputTexture", RainMaskSceneCaptureComponent.TextureTarget);
		Rendering::DrawMaterialToRenderTarget(TempTexture, PackRainMaterialDynamic);
		
		TArray<ARainBlocker> RainBlockers = TListedActors<ARainBlocker>().Array;
		
		RainBlockers.Sort();
		
		SetColorMaterialDynamic = Material::CreateDynamicMaterialInstance(this, SetColorMaterial);

		UCanvas Canvas;
		FDrawToRenderTargetContext Context;
		FVector2D A;
		FVector2D TextureSize = FVector2D(TempTexture.SizeX, TempTexture.SizeY);
		Rendering::BeginDrawCanvasToRenderTarget(TempTexture, Canvas, A, Context);
		for (ARainBlocker RainBlocker : RainBlockers)
		{
			// Transform quad in world space to texture position in texture space.
			float Size = 100.0;
			float ScaleX = RainBlocker.GetActorRelativeScale3D().Y;
			float ScaleY = RainBlocker.GetActorRelativeScale3D().X;
			FVector LocalPos = (RainBlocker.GetActorLocation() - RainMaskSceneCaptureComponent.Owner.GetActorLocation()) / RainMaskSize; 
			FVector2D LocalSize = (FVector2D(ScaleX, ScaleY) * Size) / RainMaskSize;
			LocalPos = LocalPos + FVector(1.0) * FVector(0.5); // center on underlying plane
			FVector2D pos = FVector2D(LocalPos.Y, 1.0 - LocalPos.X) * TextureSize;
			FVector2D size = LocalSize * TextureSize;
			pos -= size;
			size *= 2.0;
			if(RainBlocker.RainBlockerComponent.RainBlockerType == ERainBlockerType::ForceAddRain)
			{
				SetColorMaterialDynamic.SetVectorParameterValue(n"Color", FLinearColor(0.0, 1.0, 1.0, 1.0));
			}
			else
			{
				SetColorMaterialDynamic.SetVectorParameterValue(n"Color", FLinearColor(0.0, 0.0, 0.0, 0.0));
			}
			Canvas.DrawMaterial(SetColorMaterialDynamic, pos, size, FVector2D(0, 0), FVector2D(1, 1), RainBlocker.ActorRotation.Yaw, FVector2D(0.5, 0.5));
		}
		Rendering::EndDrawCanvasToRenderTarget(Context);
		
		UTexture2D Result = Rendering::RenderTargetCreateStaticTexture2DEditorOnly(
			TempTexture,
			"/Game/Environment/Blueprints/RainCaptures/RainMask", 
			CompressionSettings = TextureCompressionSettings::TC_Default,
			MipSettings = TextureMipGenSettings::TMGS_NoMipmaps);
			
		Target = Cast<UTexture2D>(Editor::SaveAssetAsNewPath(Result));
		EditorAsset::DeleteAsset(Result.GetPathName());
		
		TArray<UObject> Objects;
		Objects.Add(Target);
		Editor::SyncContentBrowserToAssets(Objects);
		
		ApplyRainMask();

		#endif
	}

#if EDITOR
    void InitCaptureComponent()
    {
		RainMaskSceneCaptureComponent = GetSky().RainMaskSceneCaptureComponent;
		RainMaskSceneCaptureComponent.SetWorldRotation(FRotator(-90, 0, 0)); // look down
		RainMaskSceneCaptureComponent.SetWorldLocation(Owner.GetActorLocation() + FVector(0, 0, HeightOffset));
		RainMaskSceneCaptureComponent.CaptureSource = ESceneCaptureSource::SCS_SceneDepth;
		RainMaskSceneCaptureComponent.ProjectionType = ECameraProjectionMode::Orthographic;
		RainMaskSceneCaptureComponent.bCaptureEveryFrame = false;
		RainMaskSceneCaptureComponent.bCaptureOnMovement = false;
		RainMaskSceneCaptureComponent.OrthoWidth = RainMaskSize;
		RainMaskSceneCaptureComponent.MaxViewDistanceOverride = 10000000;
		RainMaskSceneCaptureComponent.TextureTarget = RainMaskRenderTarget;
	}
#endif
	
    UFUNCTION(BlueprintOverride)
	void BeginPlay()
    {
		ApplyRainMask();
	}

	void CreateRainMaskRenderTarget()
	{
		if (RainMaskRenderTarget == nullptr)
		{
			RainMaskRenderTarget = Rendering::CreateRenderTarget2D(
				2048, 2048,
				ETextureRenderTargetFormat::RTF_R32f,
				FLinearColor(0, 0, 0, 0));
		}
	}

	UFUNCTION(CallInEditor, Category="Rain")
	void ApplyRainMask()
	{
		if (GlobalParameters != nullptr)
		{
			Material::SetVectorParameterValue(GlobalParameters, n"RainMaskSize", FLinearColor(RainMaskSize, RainMaskSize, RainMaskSize, RainMaskSize));
			Material::SetScalarParameterValue(GlobalParameters, n"RainEnabled", bRainEnabed ? 1 : 0);

			Material::SetScalarParameterValue(GlobalParameters, n"GlobalRainTiling", Tiling);
			Material::SetScalarParameterValue(GlobalParameters, n"GlobalRainStrength", Strength);
			Material::SetScalarParameterValue(GlobalParameters, n"GlobalRainSpeed", Speed);
			Material::SetScalarParameterValue(GlobalParameters, n"GlobalRainHeightOffset", HeightOffset);
			Material::SetScalarParameterValue(GlobalParameters, n"GlobalRainFilterWidth", RainMaskSize / 2048);
			Material::SetScalarParameterValue(GlobalParameters, n"GlobalRainDarkening", Darkening);
			
		}

		if (!bRainEnabed || UnpackRainMaterial == nullptr)
		{
			RainMaskRenderTarget = nullptr;
			
#if EDITOR
			if (!World.IsGameWorld())
			{
				auto LevelEditorSubsystem = UHazeLevelEditorViewportSubsystem::Get();
				LevelEditorSubsystem.SetHazeGlobalTextureForEditor(0, nullptr);
			}
#endif
			return;
		}
		
		if(!bRainEnabed)
			return;

		CreateRainMaskRenderTarget();

		UMaterialInstanceDynamic UnpackRainMaterialDynamic = Material::CreateDynamicMaterialInstance(this, UnpackRainMaterial);
		UnpackRainMaterialDynamic.SetTextureParameterValue(n"InputTexture", Target);
		Rendering::DrawMaterialToRenderTarget(RainMaskRenderTarget, UnpackRainMaterialDynamic);
		
//#if EDITOR
//		RainMaskSceneCaptureComponent.CaptureScene();
//#endif
		for (int i = 0; i < int(EHazeSplitScreenPosition::MAX); ++i)
			SceneView::SetHazeGlobalTextureForViewPosition(EHazeSplitScreenPosition(i), 0, RainMaskRenderTarget);

#if EDITOR
		if (!World.IsGameWorld())
		{
			auto LevelEditorSubsystem = UHazeLevelEditorViewportSubsystem::Get();
			LevelEditorSubsystem.SetHazeGlobalTextureForEditor(0, RainMaskRenderTarget);
		}
#endif
	}
	
	float DrawDelay = 2.0;
	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
#if EDITOR
		if(!World.IsGameWorld())
		{
			DrawDelay -= DeltaSeconds;
			if(DrawDelay < 0)
			{
				ApplyRainMask();
				SetbTickInEditor(false);
			}
		}
#endif
	}
	
}

#if EDITOR
class UGlobalRainComponentVisualizer : UHazeScriptComponentVisualizer
{
	default VisualizedClass = UGlobalRainComponent;

	UFUNCTION(BlueprintOverride)
	void VisualizeComponent(const UActorComponent Component)
	{
		const auto GlobalRain = Cast<UGlobalRainComponent>(Component);

		if(GlobalRain == nullptr)
			return;
		
		if(!GlobalRain.bRainEnabed)
			return;

		float MaxDepthApparently = 15000 * 10;
		FVector CameraPosition = GlobalRain.Owner.GetActorLocation() + FVector(0, 0, GlobalRain.HeightOffset);

		FVector Center = CameraPosition - FVector(0, 0, MaxDepthApparently);
		
		DrawWireBox(Center, FVector(GlobalRain.RainMaskSize*0.5, GlobalRain.RainMaskSize*0.5, MaxDepthApparently), FQuat::Identity, FLinearColor::LucBlue, 1000);
	}
}
#endif