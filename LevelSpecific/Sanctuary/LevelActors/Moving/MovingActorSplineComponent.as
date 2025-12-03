
struct FSplinePointExtraData
{
	UPROPERTY()
	float SomeValue = 0.0;

	UPROPERTY()
	FTransform Transform;

	UPROPERTY()
	FRuntimeFloatCurve Curve;

	FSplinePointExtraData()
	{
		Curve.AddDefaultKey(0.0, 0.0);
		Curve.AddDefaultKey(1.0, 1.0);
	}
}

class UMovingActorSplineComponent : UHazeSplineComponent
{
	default EditingSettings.bEnableVisualizeScale = true;

	UPROPERTY(EditAnywhere, Category = "Spline")
	FRuntimeFloatCurve TimeDistanceCurve;
	default TimeDistanceCurve.AddDefaultKey(0.0, 0.0);
	default TimeDistanceCurve.AddDefaultKey(1.0, 1.0);

	UPROPERTY(EditAnywhere, EditFixedSize, Category = "Spline")
	TArray<FSplinePointExtraData> SplineExtraData;

	default SplineExtraData.Add(FSplinePointExtraData());
	default SplineExtraData.Add(FSplinePointExtraData());

	int EditorSelectedIndex = 0;

	// Called when the user adds a new spline point in the editor
	void OnEditorSplinePointAddedAtIndex(int AddedSplinePointIndex) override
	{
		Print("Added: " + AddedSplinePointIndex, 1.0, FLinearColor::Green);

		FSplinePointExtraData ExtraData;
		SplineExtraData.Insert(ExtraData, AddedSplinePointIndex);

//		auto MovingActor = Cast<AMovingActor>(Owner);
//		MovingActor.AddKeyPoint(AddedSplinePointIndex);
	}

	// Called when the user deletes a spline point in the editor
	void OnEditorSplinePointRemovedAtIndex(int RemovedSplinePointIndex) override
	{
		Print("Removed: " + RemovedSplinePointIndex, 1.0, FLinearColor::Green);

		SplineExtraData.RemoveAt(RemovedSplinePointIndex);

//		auto MovingActor = Cast<AMovingActor>(Owner);
//		MovingActor.RemoveKeyPoint(RemovedSplinePointIndex);
	}

	UFUNCTION(CallInEditor)
	void SetLinearTangents()
	{
		for (int i = 0; i < SplinePoints.Num() - 1; i++)
		{
			FVector ToNextPoint = (SplinePoints[i + 1].RelativeLocation - SplinePoints[i].RelativeLocation).GetSafeNormal();
			SplinePoints[i].bOverrideTangent = true;
			SplinePoints[i].bDiscontinuousTangent = true;
			SplinePoints[i].LeaveTangent = ToNextPoint;
			SplinePoints[i].ArriveTangent = -ToNextPoint;		
		}
	
		UpdateSpline();
	}
}