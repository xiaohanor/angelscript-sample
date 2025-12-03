#if EDITOR
class USplineFocusCameraBlendVisualizer : UHazeScriptComponentVisualizer
{
	default VisualizedClass = USegmentedSplineFocusCameraBlendComponent;

	UFocusCameraBlendSplineKey SelectedSplineKey = nullptr;
	UHazeSplineComponent SplineComponent = nullptr;

	UStaticMesh ProxyCameraMesh = nullptr;
	UMaterialInterface ProxyCameraMaterial = nullptr;
	UMaterialInterface ProxyCameraHoveredMaterial = nullptr;
	UMaterialInterface ProxyCameraSelectedMaterial = nullptr;

	bool bCopyKeyPressed = false;

	UFUNCTION(BlueprintOverride)
	void VisualizeComponent(const UActorComponent Component)
	{
		USegmentedSplineFocusCameraBlendComponent SplineFocusCameraBlendComponent = Cast<USegmentedSplineFocusCameraBlendComponent>(Component);
		if (SplineFocusCameraBlendComponent == nullptr)
			return;

		SplineComponent = SplineFocusCameraBlendComponent.SplineComponent;
		if (SplineComponent == nullptr)
			return;

		LoadAssetsForFrame();

		TArray<UFocusCameraBlendSplineKey> SplineKeys;
		SplineFocusCameraBlendComponent.Owner.GetComponentsByClass(SplineKeys);
		SplineKeys.Sort();

		SetRenderForeground(true);

		// Visualize keys
		int i = 1;
		for (UFocusCameraBlendSplineKey SplineKey : SplineKeys)
		{
			FTransform TransformAlongSpline = SplineComponent.GetWorldTransformAtSplineDistance(SplineKey.DistanceAlongSpline);
			FLinearColor Color = SplineKey.VisualizerSettings.EditorColor;
			bool bSelected = SelectedSplineKey == SplineKey;

			SetHitProxy(SplineKey.Name, EVisualizerCursor::GrabHand);

			DrawSplineKeyMesh(SplineKey);

			// DrawWireDiamond(TransformAlongSpline.Location, TransformAlongSpline.Rotator(), 100, Color * 0.8);
			// DrawCircle(Transform.Location, 100, Color * 4, Normal = Transform.Rotation.ForwardVector);
			// DrawCircle(TransformAlongSpline.Location, 130, Color * (bSelected ? 5 : 0.8), Normal = TransformAlongSpline.Rotation.ForwardVector);

			FString SplineKeyName = SplineKey.Name.ToString();
			SplineKeyName.RemoveFromStart("FocusCameraBlend");
			DrawWorldString("" + SplineKeyName, TransformAlongSpline.Location, FLinearColor::White);

			i++;
		}

		// Visualize camera link
		// if (SplineFocusCameraBlendComponent.FocusCamera != nullptr)
		// {
		// 	FVector SplinePoint = SplineComponent.GetClosestSplineWorldLocationToWorldLocation(EditorViewLocation);
		// 	DrawDashedLine(SplinePoint, SplineFocusCameraBlendComponent.FocusCamera.Camera.WorldLocation, FLinearColor::Yellow, 10, 2);
		// }

		// FString String = SelectedSplineKey == nullptr ? "null" : SelectedSplineKey.Name.ToString();
		// DrawWorldString(String, SplineFocusCameraBlendComponent.Owner.ActorLocation, FLinearColor::White, 5);
	}

	void DrawSplineKeyMesh(UFocusCameraBlendSplineKey SplineKey)
	{
		UMaterialInterface Material = ProxyCameraMaterial;
		if (SelectedSplineKey == SplineKey)
			Material = ProxyCameraSelectedMaterial;
		else if (GetHoveredHitProxy() == SplineKey.Name)
			Material = ProxyCameraHoveredMaterial;

		FVector Offset = SplineKey.ForwardVector * 47.5;
		DrawMeshWithMaterial(ProxyCameraMesh, Material, SplineKey.WorldLocation + Offset, SplineKey.ComponentQuat, FVector(1.0));
	}

	UFUNCTION(BlueprintOverride)
	bool VisProxyHandleClick(FName HitProxy, FVector ClickOrigin, FVector ClickDirection, FKey Key, EInputEvent Event)
	{
		if (HitProxy.PlainNameString.Contains("SplineKey"))
		{
			// Get keys from component
			USegmentedSplineFocusCameraBlendComponent SplineFocusCameraBlendComponent = Cast<USegmentedSplineFocusCameraBlendComponent>(EditingComponent);
			if (SplineFocusCameraBlendComponent == nullptr)
				return false;

			TArray<UFocusCameraBlendSplineKey> SplineKeys;
			SplineFocusCameraBlendComponent.Owner.GetComponentsByClass(SplineKeys);

			for (UFocusCameraBlendSplineKey SplineKey : SplineKeys)
			{
				if (SplineKey.Name == HitProxy)
				{
					FScopedTransaction ST("Select Spline Key");
					Editor::SelectComponent(SplineKey);
					SelectedSplineKey = SplineKey;
					return true;
				}
			}
		}

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void EndEditing()
	{
		SelectedSplineKey = nullptr;
		SplineComponent = nullptr;
	}

	UFUNCTION(BlueprintOverride)
	bool HandleInputKey(FKey Key, EInputEvent Event)
	{
		if (Key == EKeys::LeftAlt)
		{
			if (Event == EInputEvent::IE_Pressed)
			{
				bCopyKeyPressed = true;
			}
			else if (Event == EInputEvent::IE_Released)
			{
				bCopyKeyPressed = false;
			}

			if (SelectedSplineKey != nullptr)
				return true;
		}

		if (Key == EKeys::LeftMouseButton)
		{
			if (Event == EInputEvent::IE_Released)
			{
				if (SelectedSplineKey != nullptr)
				{
					FScopedTransaction ST("Selected spline key");
					SelectedSplineKey.Modify();
					Editor::SelectComponent(SelectedSplineKey);
				}
			}
		}

		return false;
	}

	UFUNCTION(BlueprintOverride)
	bool HandleInputDelta(FVector& DeltaTranslate, FRotator& DeltaRotate, FVector& DeltaScale)
	{
		if (SelectedSplineKey == nullptr)
			return false;

		if (SplineComponent == nullptr)
			return false;

		USegmentedSplineFocusCameraBlendComponent SplineFocusCameraBlendComponent = Cast<USegmentedSplineFocusCameraBlendComponent>(EditingComponent);
			if (SplineFocusCameraBlendComponent == nullptr)
				return false;

		if (DeltaTranslate.IsZero())
			return false;

		// We are copying spline key
		if (bCopyKeyPressed)
		{
			FScopedTransaction ST("Create Spline Key");
			UFocusCameraBlendSplineKey NewSplineKey = UFocusCameraBlendSplineKey::Create(EditingComponent.Owner);
			NewSplineKey.CopyFrom(SelectedSplineKey);

			SelectedSplineKey = NewSplineKey;
			bCopyKeyPressed = false;
		}

		// Get delta in spline direction
		FVector SplineDirection = SplineComponent.GetRelativeForwardVectorAtSplineDistance(SelectedSplineKey.DistanceAlongSpline);
		FVector SplineDelta = DeltaTranslate.ConstrainToDirection(SplineDirection);

		float SplineDistanceDelta = SplineDelta.Size() * Math::Sign(SplineDelta.DotProduct(SplineDirection));
		SelectedSplineKey.DistanceAlongSpline += SplineDistanceDelta;
		SelectedSplineKey.DistanceAlongSpline = Math::Clamp(SelectedSplineKey.DistanceAlongSpline, 0.0, SplineComponent.SplineLength);

		// SelectedSplineKey.SetRelativeLocation(SplineComponent.GetRelativeLocationAtSplineDistance(SelectedSplineKey.DistanceAlongSpline));
		SelectedSplineKey.SetWorldLocation(SplineComponent.GetWorldLocationAtSplineDistance(SelectedSplineKey.DistanceAlongSpline));

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool GetWidgetLocation(FVector& OutLocation) const
	{
		if (SelectedSplineKey == nullptr)
			return false;

		if (SplineComponent == nullptr)
			return false;

		OutLocation = SelectedSplineKey.WorldLocation;
		return true;
	}

	void LoadAssetsForFrame()
	{
		ProxyCameraMesh = Cast<UStaticMesh>(Editor::LoadAsset(n"/Engine/EditorMeshes/MatineeCam_SM.MatineeCam_SM"));
		ProxyCameraMaterial = Cast<UMaterialInterface>(Editor::LoadAsset(n"/Engine/EngineDebugMaterials/M_SimpleTranslucent.M_SimpleTranslucent"));
		ProxyCameraHoveredMaterial = Cast<UMaterialInterface>(Editor::LoadAsset(n"/Engine/EngineDebugMaterials/M_SimpleUnlitTranslucent.M_SimpleUnlitTranslucent"));
		ProxyCameraSelectedMaterial = Cast<UMaterialInterface>(Editor::LoadAsset(n"/Game/Editor/SplineEditor/SplineEditor_Point_Selected_Material.SplineEditor_Point_Selected_Material"));
	}
}
#endif