
class ACustomMergeSplitManager : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

#if EDITOR
	UPROPERTY(DefaultComponent)
	UEditorBillboardComponent EditorIcon;
#endif

	UPROPERTY(EditAnywhere)
	UMaterialInterface SplitScreenMaterial;

	UPROPERTY(EditAnywhere)
	UMaterialInterface CustomMergeMaterial;

	// Projection offset for each of the player views while this is active
	UPROPERTY(EditAnywhere)
	TPerPlayer<FVector2D> BaseOffCenterProjectionOffset;

	UPROPERTY(VisibleInstanceOnly, AdvancedDisplay)
	UTextureRenderTarget2D MergeMask;
	
	UPROPERTY(VisibleInstanceOnly, AdvancedDisplay)
	TPerPlayer<UMaterialInstanceDynamic> PerPlayerInstances;
	UPROPERTY(VisibleInstanceOnly, AdvancedDisplay)
	UMaterialInstanceDynamic SplitScreenInstance;
	bool bEnabled;

	default PrimaryActorTick.TickGroup = ETickingGroup::TG_LastDemotable;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
	}

	UFUNCTION(BlueprintOverride)
	void EndPlay(EEndPlayReason EndPlayReason)
	{
		if (EndPlayReason != EEndPlayReason::EndPlayInEditor)
		{
			if (bEnabled)
				DeactivateCustomSplit();
		}
	}

	UFUNCTION()
	void ActivateCustomSplit()
	{
		if (bEnabled)
			return;

		bEnabled = true;
		SetActorTickEnabled(true);

		SceneView::SetSplitScreenMode(EHazeSplitScreenMode::CustomMerge);

		FVector2D Resolution = SceneView::GetFullViewportResolution();
		MergeMask = Rendering::CreateRenderTarget2D(
			Math::Max(10, int(Resolution.X)),
			Math::Max(10, int(Resolution.Y)),
			ETextureRenderTargetFormat::RTF_R8
		);

		if (CustomMergeMaterial != nullptr)
		{
			for (auto Player : Game::Players)
			{
				PerPlayerInstances[Player] = Material::CreateDynamicMaterialInstance(this, CustomMergeMaterial);
				PerPlayerInstances[Player].SetScalarParameterValue(n"ViewportIndex", int(Player.Player));
				PerPlayerInstances[Player].SetTextureParameterValue(n"CustomMergeMask", MergeMask);
				SceneView::SetSplitScreenCustomMergeMaterial(Player, PerPlayerInstances[Player]);
			}
		}

		if (SplitScreenMaterial != nullptr)
		{
			SplitScreenInstance = Material::CreateDynamicMaterialInstance(this, SplitScreenMaterial);
		}

		for (auto Player : Game::Players)
		{
			FVector2D Offset = BaseOffCenterProjectionOffset[Player];

			auto CameraView = Cast<UHazeCameraViewPoint>(Player.GetViewPoint());
			CameraView.ApplyOffCenterProjectionOffset(Offset, this);
		}
	}
	
	UFUNCTION()
	void DeactivateCustomSplit()
	{
		if (!bEnabled)
			return;

		bEnabled = false;
		SetActorTickEnabled(true);

		SceneView::SetSplitScreenMode(EHazeSplitScreenMode::Vertical);
		for (auto Player : Game::Players)
		{
			SceneView::SetSplitScreenCustomMergeMaterial(Player, nullptr);

			auto CameraView = Cast<UHazeCameraViewPoint>(Player.GetViewPoint());
			if (CameraView != nullptr)
				CameraView.ClearOffCenterProjectionOffset(this);
		}
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		if (!bEnabled)
		{
			SetActorTickEnabled(false);
			return;
		}

		if (SplitScreenInstance != nullptr && MergeMask != nullptr)
		{
			FVector2D Resolution = SceneView::GetFullViewportResolution();
			Rendering::ResizeRenderTarget(MergeMask, int(Resolution.X), int(Resolution.Y));
			Rendering::DrawMaterialToRenderTarget(MergeMask, SplitScreenInstance);
		}
	}

};