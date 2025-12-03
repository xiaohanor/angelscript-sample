class UMovingSceneComponentVisualizer : UHazeScriptComponentVisualizer
{
	default VisualizedClass = UMovingSceneComponent;

	UFUNCTION(BlueprintOverride)
	void VisualizeComponent(UActorComponent Component)
	{
		auto MovingSceneComponent = Cast<UMovingSceneComponent>(Component);
	/*
		for (auto SplineExtraData : MovingSceneComponent.Spline.SplineExtraData)
		{
			FTransform KeyWorldTransform = MovingSceneComponent.Owner.ActorTransform;
			KeyWorldTransform = SplineExtraData.Transform * KeyWorldTransform;
			DrawCoordinateSystem(KeyWorldTransform.Location, KeyWorldTransform.Rotation.Rotator(), 100.0, 5.0);
		}
	*/
	}
}

class UMovingSceneComponentDetails : UHazeScriptDetailCustomization
{
/*
	default DetailClass = UMovingSceneComponent;
	UHazeImmediateDrawer Drawer;
	UMovingSceneComponent MovingSceneComponent;

	UFUNCTION(BlueprintOverride)
	void CustomizeDetails()
	{
		EditCategory(n"MovingDetails");
		Drawer = AddImmediateRow(n"MovingDetails");

		MovingSceneComponent = Cast<UMovingSceneComponent>(GetCustomizedObject());
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaTime)
	{
		if (!Drawer.IsVisible())
			return;

		auto Section = Drawer.Begin();
		if (Section.Button("Hello"))
			Print("Hello");

		Section.Text("This is text :)");
		auto SubSection = Section.Section("Advanced");
		SubSection.Text("This is advanced stuff");
	}
*/
}


class UMovingSceneComponent : USceneComponent
{
	UPROPERTY(EditAnywhere, Category = "MovingComponent")
	float TotalDuration = 0.0;

	UPROPERTY(EditAnywhere, Category = "MovingComponent")
	bool bIsMoving = true;

	UMovingActorSplineComponent Spline;

	float BaseSpeed = 200.0;

	float DistanceOnSpline = 0.0;

	float SpeedFactor = 1.0;

	UFUNCTION(BlueprintCallable, DevFunction)
	void StartMoving(float _SpeedFactor = 1.0)
	{
		SpeedFactor = _SpeedFactor;
		SetComponentTickEnabled(true);
	}

	UFUNCTION(BlueprintCallable)
	void StopMoving()
	{
		SetComponentTickEnabled(false);
	}

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		if (!bIsMoving)
			StopMoving();
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		DistanceOnSpline += BaseSpeed * DeltaSeconds * SpeedFactor;
		DistanceOnSpline = Math::Clamp(DistanceOnSpline, 0.0, Spline.SplineLength);
	
		UpdateTransform(DistanceOnSpline);
	}

	void Preview(float PreviewTime)
	{
		UpdateTransform(PreviewTime);
	}

	void UpdateTransform(float Distance)
	{
		int CurrentSegment = 0;

		for (int i = 1; i < Spline.SplinePoints.Num(); i++)
		{
			if (Distance < Spline.GetSplineDistanceAtSplinePointIndex(i))
			{
				CurrentSegment = i - 1;
				break;
			}
		}

		float SplineLength = Spline.SplineLength;
		float SegmentStartDistance = Spline.GetSplineDistanceAtSplinePointIndex(CurrentSegment);
		float SegmentEndDistance = Spline.GetSplineDistanceAtSplinePointIndex(CurrentSegment + 1);
		float SegmentLength = SegmentEndDistance - SegmentStartDistance;
		float DistanceOnSegment = Distance - SegmentStartDistance;

		float InTime = DistanceOnSegment / SegmentLength;
//		float CurveValue = Spline.SplineExtraData[CurrentSegment].Curve.GetFloatValue(InTime);
		float CurveValue = Spline.TimeDistanceCurve.GetFloatValue(Distance / SplineLength);

//		float ModifiedDistanceOnSpline = SegmentStartDistance + SegmentLength * CurveValue;
		float ModifiedDistanceOnSpline = SplineLength * CurveValue;

		PrintToScreen("CurrentSegment: " + CurrentSegment, 0.0, FLinearColor::Green);
		PrintToScreen("SegmentLength: " + SegmentLength, 0.0, FLinearColor::Green);
		PrintToScreen("DistanceOnSpline: " + Distance, 0.0, FLinearColor::Green);
		PrintToScreen("CurveValue: " + CurveValue, 0.0, FLinearColor::Green);
	
#if EDITOR
		if (bHazeEditorOnlyDebugBool)
			Debug::DrawDebugPoint(Spline.GetWorldLocationAtSplineDistance(ModifiedDistanceOnSpline), 50.0, FLinearColor::Green, 0.0);
#endif

		FTransform LerpedTransform = LerpTransform(Spline.SplineExtraData[CurrentSegment].Transform, Spline.SplineExtraData[CurrentSegment + 1].Transform, CurveValue);
		FTransform TransformOnSpline = Spline.GetWorldTransformAtSplineDistance(ModifiedDistanceOnSpline);
		FTransform FinalTransform = TransformOnSpline;
		FinalTransform.Rotation = LerpedTransform.Rotation;

		SetWorldTransform(FinalTransform);
	}

	FTransform LerpTransform(FTransform A, FTransform B, float Alpha)
	{
		FTransform NewTransform;
		NewTransform.Location = Math::Lerp(A.Location, B.Location, Alpha);
		NewTransform.Rotation = FQuat::Slerp(A.Rotation, B.Rotation, Alpha);

		return NewTransform;
	}
}