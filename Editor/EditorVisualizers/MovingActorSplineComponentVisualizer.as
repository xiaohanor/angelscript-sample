
class UMovingActorSplineComponentVisualizer : UHazeSplineEditor
{
	default VisualizedClass = UMovingActorSplineComponent;

	FVector WidgetLocationOffset = FVector(0.0, 0.0, 100.0);
	bool bIsDataSelected = false;
	int SelectedDataIndex = 0;

	UFUNCTION(BlueprintOverride)
	void VisualizeComponent(UActorComponent Component)
	{
		Super::VisualizeComponent(Component);
		
		auto MovingActorSplineComponent = Cast<UMovingActorSplineComponent>(Component);

		for (int i = 0; i < MovingActorSplineComponent.SplineExtraData.Num(); i++)
		{
			FTransform WorldTransform = MovingActorSplineComponent.WorldTransform;

			FTransform SplinePointRelativeTransform;
			SplinePointRelativeTransform.Location = MovingActorSplineComponent.SplinePoints[i].RelativeLocation;
			SplinePointRelativeTransform.Rotation = FQuat::MakeFromXZ(MovingActorSplineComponent.SplinePoints[i].LeaveTangent, MovingActorSplineComponent.SplinePoints[i].RelativeRotation.UpVector);

			FQuat CustomPointRotation = MovingActorSplineComponent.SplineExtraData[i].Transform.Rotation;

			FVector WidgetLocation = (SplinePointRelativeTransform * WorldTransform).TransformPositionNoScale(WidgetLocationOffset);
//			FRotator WidgetRotation = (SplinePointRelativeTransform * WorldTransform).TransformRotation(MovingActorSplineComponent.SplineExtraData[i].Transform.Rotation).Rotator();
//			FRotator WidgetRotation = (WorldTransform * SplinePointRelativeTransform * MovingActorSplineComponent.SplineExtraData[i].Transform).Rotation.Rotator();
			FRotator WidgetRotation = (MovingActorSplineComponent.SplineExtraData[i].Transform * SplinePointRelativeTransform * WorldTransform).Rotation.Rotator();

//			FRotator WidgetRotation = MovingActorSplineComponent.SplineExtraData[i].Transform.Rotation.Inverse().Rotator();

			// Set locations of the extradata
			MovingActorSplineComponent.SplineExtraData[i].Transform.Location = SplinePointRelativeTransform.TransformPositionNoScale(WidgetLocationOffset);

			FName RotationProxy = n"EditableRotation";
			RotationProxy.SetNumber(i);

			SetHitProxy(RotationProxy, EVisualizerCursor::GrabHand);

			DrawCoordinateSystem(WidgetLocation, WidgetRotation, 100.0, 20.0);

			ClearHitProxy();
		}
	}

	UFUNCTION(BlueprintOverride)
	void EndEditing()
	{
		bIsDataSelected = false;

		Super::EndEditing();
	}

	// Handle when the point with the hitproxy is clicked 
	UFUNCTION(BlueprintOverride)
	bool VisProxyHandleClick(FName HitProxy, FVector ClickOrigin, FVector ClickDirection, FKey Key, EInputEvent Event)
	{
		Print("HitProxy: " + HitProxy, 1.0, FLinearColor::Green);

		if (HitProxy.IsEqual(n"EditableRotation", bCompareNumber = false))
		{
			auto MovingActorSplineComponent = Cast<UMovingActorSplineComponent>(EditingComponent);

			Selection.Clear();
			SelectedDataIndex = HitProxy.GetNumber();
			bIsDataSelected = true;

			MovingActorSplineComponent.EditorSelectedIndex = SelectedDataIndex;

			Print("SelectedDataIndex: " + SelectedDataIndex, 1.0, FLinearColor::Green);

			return true;
		}
		else
		{
			bIsDataSelected = false;
		}

		return	Super::VisProxyHandleClick(HitProxy, ClickOrigin, ClickDirection, Key, Event);
	}

	// Used by the editor to determine where the transform gizmo ends up
	UFUNCTION(BlueprintOverride)
	bool GetWidgetLocation(FVector& OutLocation) const
	{
		auto MovingActorSplineComponent = Cast<UMovingActorSplineComponent>(EditingComponent);

		if (bIsDataSelected)
		{
			// Override gizmo location so it's at our editable offset location
			FVector OutLocationWorldSpace = (MovingActorSplineComponent.SplineExtraData[SelectedDataIndex].Transform * MovingActorSplineComponent.WorldTransform).Location;
			OutLocation = OutLocationWorldSpace;
			return true;
		}
	
		return Super::GetWidgetLocation(OutLocation);
	}

	// Used by the editor to determine what the coordinate system for the transform gizmo should be
	UFUNCTION(BlueprintOverride)
	bool GetCustomInputCoordinateSystem(EVisualizerCoordinateSystem CoordSystem, EVisualizerWidgetMode WidgetMode, FTransform& OutTransform) const
	{
		auto MovingActorSplineComponent = Cast<UMovingActorSplineComponent>(EditingComponent);

		// For this example, we set the transform widget so it always has the X axis at a specific angle
		if (bIsDataSelected)
			OutTransform = MovingActorSplineComponent.SplineExtraData[SelectedDataIndex].Transform;
		
		return Super::GetCustomInputCoordinateSystem(CoordSystem, WidgetMode, OutTransform);
	}


	// Used by the editor when the transform gizmo is moved while we are overriding it
	UFUNCTION(BlueprintOverride)
	bool HandleInputDelta(FVector& DeltaTranslate, FRotator& DeltaRotate, FVector& DeltaScale)
	{
		if (bIsDataSelected)
		{
			auto MovingActorSplineComponent = Cast<UMovingActorSplineComponent>(EditingComponent);

			if (!DeltaRotate.IsNearlyZero())
			{
			//	MovingActorSplineComponent.SplineExtraData[SelectedDataIndex].Transform.Rotation = MovingActorSplineComponent.SplineExtraData[SelectedDataIndex].Transform.Rotation + DeltaRotate.Quaternion();

				FQuat NewRot = MovingActorSplineComponent.SplineExtraData[SelectedDataIndex].Transform.Rotation;
				NewRot = DeltaRotate.Quaternion() * NewRot;
			//	NewRot = MovingActorSplineComponent.SplineExtraData[SelectedDataIndex].Transform.Rotation.Inverse() * NewRot;
			//	MovingActorSplineComponent.SplineExtraData[SelectedDataIndex].Transform.Rotation = MovingActorSplineComponent.WorldTransform.InverseTransformRotation(NewRot);
				MovingActorSplineComponent.SplineExtraData[SelectedDataIndex].Transform.Rotation = NewRot;

				ClearCachedRotationForWidget();
			}

			return true;
		}

		return	Super::HandleInputDelta(DeltaTranslate, DeltaRotate, DeltaScale);
	}

}