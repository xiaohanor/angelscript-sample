
class UExampleSelectableVisualizerComponent : USceneComponent
{
	UPROPERTY(EditAnywhere)
	FVector EditableOffset = FVector(0, 0, 100);
};

class UExampleVisualizerSelectable : UHazeScriptComponentVisualizer
{
	default VisualizedClass = UExampleSelectableVisualizerComponent;

	bool bIsOffsetSelected = false;

	UFUNCTION(BlueprintOverride)
	void VisualizeComponent(const UActorComponent InComponent)
	{
		auto SelectableComponent = Cast<UExampleSelectableVisualizerComponent>(InComponent);

		FTransform CompTransform = SelectableComponent.WorldTransform;

		// Render the handle in foreground drawing mode so it's in front of stuff
		SetRenderForeground(true);

		// Set a hit proxy for what we're rendering so we can capture clicks
		SetHitProxy(n"EditableOffset", EVisualizerCursor::GrabHand);

		// Draw the 'handle' for the editable offset
		DrawPoint(
			CompTransform.TransformPosition(SelectableComponent.EditableOffset),
			FLinearColor::Red,
			100.0,
		);
	}

	UFUNCTION(BlueprintOverride)
	void EndEditing()
	{
		bIsOffsetSelected = false;
	}

	// Handle when the point with the hitproxy is clicked 
	UFUNCTION(BlueprintOverride)
	bool VisProxyHandleClick(FName HitProxy, FVector ClickOrigin, FVector ClickDirection, FKey Key,
							 EInputEvent Event)
	{
		if (HitProxy == n"EditableOffset")
		{
			bIsOffsetSelected = true;
			return true;
		}

		return false;
	}

	// Used by the editor to determine where the transform gizmo ends up
	UFUNCTION(BlueprintOverride)
	bool GetWidgetLocation(FVector& OutLocation) const
	{
		auto SelectableComponent = Cast<UExampleSelectableVisualizerComponent>(EditingComponent);

		if (bIsOffsetSelected)
		{
			// Override gizmo location so it's at our editable offset location
			OutLocation = SelectableComponent.WorldTransform.TransformPosition(SelectableComponent.EditableOffset);
			return true;
		}

		// Not currently overriding the gizmo location
		return false;
	}

	// Used by the editor to determine what the coordinate system for the transform gizmo should be
	UFUNCTION(BlueprintOverride)
	bool GetCustomInputCoordinateSystem(EVisualizerCoordinateSystem CoordSystem,
										EVisualizerWidgetMode WidgetMode, FTransform& OutTransform) const
	{
		if (!bIsOffsetSelected)
			return false;

		// For this example, we set the transform widget so it always has the X axis at a specific angle
		OutTransform = FTransform::MakeFromXZ(FVector(0.5, 0.5, 0.2), FVector::UpVector);

		return true;
	}

	// Used by the editor when the transform gizmo is moved while we are overriding it
	UFUNCTION(BlueprintOverride)
	bool HandleInputDelta(FVector& DeltaTranslate, FRotator& DeltaRotate, FVector& DeltaScale)
	{
		if (!bIsOffsetSelected)
			return false;

		auto SelectableComponent = Cast<UExampleSelectableVisualizerComponent>(EditingComponent);
		if (!DeltaTranslate.IsNearlyZero())
		{
			FVector LocalTranslation = SelectableComponent.WorldTransform.InverseTransformVector(DeltaTranslate);
			SelectableComponent.EditableOffset += LocalTranslation;
		}

		return true;
	}


};