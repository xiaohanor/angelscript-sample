const FVector SCENE_CAPTURE_OFFSET(-100000.0, -100000.0, 50000.0);

class ASplitOverlaySceneManager : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

#if EDITOR
	UPROPERTY(DefaultComponent)
	UEditorBillboardComponent EditorIcon;
#endif

	UPROPERTY(DefaultComponent)
	USceneCaptureComponent2D SceneCapture;
	default SceneCapture.bConsiderUnrenderedOpaquePixelAsFullyTranslucent = true;
	default SceneCapture.PrimitiveRenderMode = ESceneCapturePrimitiveRenderMode::PRM_UseShowOnlyList;
	default SceneCapture.CaptureSource = ESceneCaptureSource::SCS_SceneColorHDR;
	default SceneCapture.bCaptureEveryFrame = false;
	default SceneCapture.bCaptureOnMovement = false;
	default SceneCapture.bAlwaysPersistRenderingState = true;
	default SceneCapture.bAutoActivate = false;

	UPROPERTY(EditAnywhere)
	bool bAutoActivate = false;
	
	UPROPERTY(EditAnywhere)
	TSubclassOf<USplitOverlaySceneWidget> OverlayWidget;

	private bool bEnabled = false;
	private UTextureRenderTarget2D OverlayRT;
	private USplitOverlaySceneWidget Widget;

	default PrimaryActorTick.bStartWithTickEnabled = false;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		if (bAutoActivate)
			ActivateOverlay();
	}

	UFUNCTION()
	void ActivateOverlay()
	{
		bEnabled = true;
		SetActorTickEnabled(true);

		SceneCapture.SetAbsolute(true, true, true);
		SceneCapture.SetWorldLocationAndRotation(SCENE_CAPTURE_OFFSET, FRotator::ZeroRotator);
		SceneCapture.Activate();

		FVector2D Resolution = SceneView::GetFullViewportResolution();
		OverlayRT = Rendering::CreateRenderTarget2D(
			Math::Max(10, int(Resolution.X)),
			Math::Max(10, int(Resolution.Y)),
			ETextureRenderTargetFormat::RTF_RGB10A2
		);
		SceneCapture.TextureTarget = OverlayRT;

		Widget = Widget::AddFullscreenWidget(OverlayWidget);
		Widget.OverlayRT = OverlayRT;
		Widget.Init();
	}

	UFUNCTION()
	void DeactivateOverlay()
	{
		bEnabled = false;
		SetActorTickEnabled(false);
		SceneCapture.Deactivate();

		OverlayRT = nullptr;

		if (Widget != nullptr)
		{
			Widget::RemoveFullscreenWidget(Widget);
			Widget = nullptr;
		}
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		if (bEnabled && OverlayRT != nullptr)
		{
			FVector2D Resolution = SceneView::GetFullViewportResolution();
			Rendering::ResizeRenderTarget(OverlayRT, int(Resolution.X), int(Resolution.Y));
			SceneCapture.CaptureScene();
		}
	}
};

class USplitOverlayScreenSpacePositionComponent : UActorComponent
{
	private FVector2D ScreenPosition(0.5, 0.5);
	private float Depth = 200.0;
	private ASplitOverlaySceneManager Manager;

	UPROPERTY(EditAnywhere)
	bool bAutoActivateScreenPosition = false;

	UPROPERTY(EditAnywhere, Meta = (EditCondition = "bAutoActivateScreenPosition", EditConditionHides))
	ASplitOverlaySceneManager AutoActivateManager;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		if (bAutoActivateScreenPosition && AutoActivateManager != nullptr)
			ActivateScreenPosition(AutoActivateManager);
	}

	UFUNCTION()
	void ActivateScreenPosition(ASplitOverlaySceneManager OverlayManager)
	{
		Manager = OverlayManager;
		Manager.SceneCapture.ShowOnlyActors.Add(Owner);
		UpdatePosition();
	}

	UFUNCTION()
	void DeactivateScreenPosition()
	{
		if (Manager != nullptr)
		{
			Manager.SceneCapture.ShowOnlyActors.Remove(Owner);
			Manager = nullptr;
		}
	}

	UFUNCTION()
	void SetScreenPosition(FVector2D InScreenPosition, float InDepth)
	{
		ScreenPosition = InScreenPosition;
		Depth = InDepth;
		UpdatePosition();
	}

	private void UpdatePosition()
	{
		if (Manager == nullptr)
			return;

		FVector Location = SCENE_CAPTURE_OFFSET + FVector::ForwardVector * Depth;
		Owner.SetActorLocation(Location);
	}
};

UCLASS(Abstract)
class USplitOverlaySceneWidget : UHazeUserWidget
{
	UPROPERTY(BlueprintReadOnly, NotEditable)
	UTextureRenderTarget2D OverlayRT;

	UPROPERTY(EditAnywhere)
	UMaterialInterface OverlayMaterial;

	UPROPERTY(BindWidget)
	UImage OverlayImage;

	UMaterialInstanceDynamic OverlayInstance;

	void Init()
	{
		OverlayInstance = Material::CreateDynamicMaterialInstance(this, OverlayMaterial);
		OverlayInstance.SetTextureParameterValue(n"OverlayTexture", OverlayRT);
		OverlayImage.SetBrushFromMaterial(OverlayInstance);
	}
};
