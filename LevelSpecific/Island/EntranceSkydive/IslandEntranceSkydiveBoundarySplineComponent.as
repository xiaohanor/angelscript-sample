namespace IslandEntranceSkydiveBoundary
{
	UFUNCTION()
	void IslandEntranceSkydiveBoundaryAddBoundaryDisable(ASplineActor SplineActor, FInstigator Instigator)
	{
		auto Boundary = UIslandEntranceSkydiveBoundarySplineComponent::Get(SplineActor);
		devCheck(Boundary != nullptr, "Tried to add boundary disable on an actor that doesn't have a boundary component");
		Boundary.AddBoundaryDisable(Instigator);
	}

	UFUNCTION()
	void IslandEntranceSkydiveBoundaryRemoveBoundaryDisable(ASplineActor SplineActor, FInstigator Instigator)
	{
		auto Boundary = UIslandEntranceSkydiveBoundarySplineComponent::Get(SplineActor);
		devCheck(Boundary != nullptr, "Tried to remove boundary disable on an actor that doesn't have a boundary component");
		Boundary.RemoveBoundaryDisable(Instigator);
	}

	UFUNCTION(BlueprintPure)
	bool IslandEntranceSkydiveBoundaryIsBoundaryDisabled(ASplineActor SplineActor)
	{
		auto Boundary = UIslandEntranceSkydiveBoundarySplineComponent::Get(SplineActor);
		devCheck(Boundary != nullptr, "Tried to check is boundary disabled on an actor that doesn't have a boundary component");
		return Boundary.IsBoundaryDisabled();
	}
}

UCLASS(NotBlueprintable, NotPlaceable)
class UIslandEntranceSkydiveBoundarySplineContainerComponent : UActorComponent
{
	TArray<UIslandEntranceSkydiveBoundarySplineComponent> BoundarySplineComponents;
}

enum EIslandEntranceSkydiveBoundarySplineShape
{
	Cylinder,
	Box
}

class UIslandEntranceSkydiveBoundarySplineComponent : UActorComponent
{
	UPROPERTY(EditAnywhere, Category = "Boundary Spline")
	EIslandEntranceSkydiveBoundarySplineShape Shape;

	UPROPERTY(EditAnywhere, Category = "Boundary Spline", Meta = (EditCondition = "Shape == EIslandEntranceSkydiveBoundarySplineShape::Cylinder", EditConditionHides))
	float BaseCylinderRadius = 500.0;

	UPROPERTY(EditAnywhere, Category = "Boundary Spline", Meta = (EditCondition = "Shape == EIslandEntranceSkydiveBoundarySplineShape::Box", EditConditionHides))
	FVector2D BaseBoxExtent = FVector2D(500.0, 500.0);

	/* x axis represents the alpha distance from the spline, y axis represents the counter force multiplier */
	UPROPERTY(EditAnywhere, Category = "Boundary Spline")
	FRuntimeFloatCurve CounterForceCurve;
	default CounterForceCurve.AddDefaultKey(0.0, 0.0);
	default CounterForceCurve.AddDefaultKey(1.0, 1.0);
	default CounterForceCurve.AddDefaultKey(2.0, 2.0);

	UPROPERTY(EditAnywhere, Category = "Visualizer")
	float ForceVisualizerSplineDistance = 0.0;

	UPROPERTY(EditAnywhere, Category = "Visualizer")
	bool bAnimateForceVisualizer = true;

	UPROPERTY(EditAnywhere, Category = "Visualizer", Meta = (EditCondition = "bAnimateForceVisualizer", EditConditionHides))
	float ForceVisualizerAnimationDuration = 1.0;

	UPROPERTY(EditAnywhere, Category = "Visualizer", Meta = (EditCondition = "!bAnimateForceVisualizer", EditConditionHides, ClampMin="0", ClampMax="1"))
	float ForceVisualizerAlpha = 0.0;

	UHazeSplineComponent Spline;
	private UIslandEntranceSkydiveBoundarySplineContainerComponent BoundaryContainerComp;
	private TArray<FInstigator> DisableInstigators;

	UFUNCTION(BlueprintOverride)
	void ConstructionScript()
	{
		Spline = Spline::GetGameplaySpline(Owner);
		devCheck(Spline != nullptr, "Can't place this component on an actor with no spline");

		ForceVisualizerSplineDistance = Math::Clamp(ForceVisualizerSplineDistance, 0.0, Spline.SplineLength);
		ForceVisualizerAlpha = Math::Saturate(ForceVisualizerAlpha);
	}

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		Spline = Spline::GetGameplaySpline(Owner);
		BoundaryContainerComp = UIslandEntranceSkydiveBoundarySplineContainerComponent::GetOrCreate(Game::Mio);
		OnBoundaryEnabled();
	}

	UFUNCTION(BlueprintOverride)
	void EndPlay(EEndPlayReason EndPlayReason)
	{
		OnBoundaryDisabled();
	}

	UFUNCTION()
	void AddBoundaryDisable(FInstigator Instigator)
	{
		bool bWasDisabled = IsBoundaryDisabled();
		DisableInstigators.AddUnique(Instigator);

		if(!bWasDisabled)
		{
			OnBoundaryDisabled();
		}
	}

	UFUNCTION()
	void RemoveBoundaryDisable(FInstigator Instigator)
	{
		bool bWasDisabled = IsBoundaryDisabled();
		DisableInstigators.RemoveSingleSwap(Instigator);

		if(bWasDisabled && !IsBoundaryDisabled())
		{
			OnBoundaryEnabled();
		}
	}

	UFUNCTION(BlueprintPure)
	bool IsBoundaryDisabled() const
	{
		return DisableInstigators.Num() > 0;
	}

	void OnBoundaryEnabled()
	{
		BoundaryContainerComp.BoundarySplineComponents.AddUnique(this);
	}

	void OnBoundaryDisabled()
	{
		BoundaryContainerComp.BoundarySplineComponents.RemoveSingleSwap(this);
	}

	// Takes a world location and returns the distance alpha to the closest point on the spline
	float GetDistanceAlphaToCenter(FVector Location)
	{
		FTransform ClosestTransform;
		return GetDistanceAlphaToCenter(Location, ClosestTransform);
	}

	// Takes a world location and returns the distance alpha to the closest point on the spline
	float GetDistanceAlphaToCenter(FVector Location, FTransform&out ClosestTransform)
	{
		ClosestTransform = Spline.GetClosestSplineWorldTransformToWorldLocation(Location);
		FVector LocalLocation = ClosestTransform.InverseTransformPosition(Location);

		return GetLocalDistanceAlphaToCenter(LocalLocation);
	}

	// Takes a local location to the closest transform on the spline and returns the distance alpha to center
	float GetLocalDistanceAlphaToCenter(FVector LocalLocation)
	{
		FVector Location = LocalLocation;
		Location.X = 0.0;

		float Alpha = 0.0;
		if(Shape == EIslandEntranceSkydiveBoundarySplineShape::Cylinder)
		{
			Alpha = Location.Size() / BaseCylinderRadius;
		}
		else if(Shape == EIslandEntranceSkydiveBoundarySplineShape::Box)
		{
			float AlphaX = Math::Abs(Location.Y / BaseBoxExtent.X);
			float AlphaY = Math::Abs(Location.Z / BaseBoxExtent.Y);

			Alpha = AlphaX > AlphaY ? AlphaX : AlphaY;
		}
		else
			devError("Forgot to add case");

		return CounterForceCurve.GetFloatValue(Alpha);
	}
}

class UIslandEntranceSkydiveBoundarySplineComponentVisualizer : UHazeScriptComponentVisualizer
{
	default VisualizedClass = UIslandEntranceSkydiveBoundarySplineComponent;

	const float VolumeLineThickness = 10.0;
	const FLinearColor VolumeColor = FLinearColor::LucBlue;

	UFUNCTION(BlueprintOverride)
	void VisualizeComponent(const UActorComponent Component)
	{
		auto Boundary = Cast<UIslandEntranceSkydiveBoundarySplineComponent>(Component);
		UHazeSplineComponent Spline = Spline::GetGameplaySpline(Boundary.Owner);

		DrawVolume(Spline, Boundary);
		DrawForceVectors(Spline, Boundary);
	}

	void DrawVolume(UHazeSplineComponent Spline, UIslandEntranceSkydiveBoundarySplineComponent Boundary)
	{
		const float StepDistance = 200.0;

		float CurrentDist = 0.0;
		FTransform CurrentTransform = Spline.GetWorldTransformAtSplineDistance(CurrentDist);

		FVector Point1, Point2, Point3, Point4;
		if(Boundary.Shape == EIslandEntranceSkydiveBoundarySplineShape::Box)
		{
			GetBoxCorners(CurrentTransform, Boundary, Point1, Point2, Point3, Point4);
			DrawSquare(Point1, Point2, Point3, Point4);
		}
		else if(Boundary.Shape == EIslandEntranceSkydiveBoundarySplineShape::Cylinder)
		{
			GetCylinderEdgePoints(CurrentTransform, Boundary, Point1, Point2, Point3, Point4);
			DrawScaledCircle(CurrentTransform, Boundary.BaseCylinderRadius);
		}
		else
			devError("Forgot to add case!");

		while(CurrentDist < Spline.SplineLength)
		{
			bool bFinal = false;
			CurrentDist += StepDistance;
			if(CurrentDist >= Spline.SplineLength)
			{
				CurrentDist = Spline.SplineLength;
				bFinal = true;
			}
			CurrentTransform = Spline.GetWorldTransformAtSplineDistance(CurrentDist);

			if(Boundary.Shape == EIslandEntranceSkydiveBoundarySplineShape::Box)
			{
				FVector Temp1, Temp2, Temp3, Temp4;
				GetBoxCorners(CurrentTransform, Boundary, Temp1, Temp2, Temp3, Temp4);

				DrawLine(Point1, Temp1, VolumeColor, VolumeLineThickness);
				DrawLine(Point2, Temp2, VolumeColor, VolumeLineThickness);
				DrawLine(Point3, Temp3, VolumeColor, VolumeLineThickness);
				DrawLine(Point4, Temp4, VolumeColor, VolumeLineThickness);

				Point1 = Temp1;
				Point2 = Temp2;
				Point3 = Temp3;
				Point4 = Temp4;

				if(bFinal)
					DrawSquare(Point1, Point2, Point3, Point4);
			}
			else if(Boundary.Shape == EIslandEntranceSkydiveBoundarySplineShape::Cylinder)
			{
				FVector Temp1, Temp2, Temp3, Temp4;
				GetCylinderEdgePoints(CurrentTransform, Boundary, Temp1, Temp2, Temp3, Temp4);

				DrawLine(Point1, Temp1, VolumeColor, VolumeLineThickness);
				DrawLine(Point2, Temp2, VolumeColor, VolumeLineThickness);
				DrawLine(Point3, Temp3, VolumeColor, VolumeLineThickness);
				DrawLine(Point4, Temp4, VolumeColor, VolumeLineThickness);

				Point1 = Temp1;
				Point2 = Temp2;
				Point3 = Temp3;
				Point4 = Temp4;

				if(bFinal)
					DrawScaledCircle(CurrentTransform, Boundary.BaseCylinderRadius);
			}
			else
				devError("Forgot to add case!");
		}
	}

	void DrawForceVectors(UHazeSplineComponent Spline, UIslandEntranceSkydiveBoundarySplineComponent Boundary)
	{
		float VectorMaxLength = 250.0;

		if(Boundary.Shape == EIslandEntranceSkydiveBoundarySplineShape::Cylinder)
		{
			VectorMaxLength = Boundary.BaseCylinderRadius * 0.5;
		}
		else if(Boundary.Shape == EIslandEntranceSkydiveBoundarySplineShape::Box)
		{
			VectorMaxLength = (Boundary.BaseBoxExtent.X < Boundary.BaseBoxExtent.Y ? Boundary.BaseBoxExtent.X : Boundary.BaseBoxExtent.Y) * 0.5;
		}

		const float LineThickness = VolumeLineThickness;
		const float SphereRadius = LineThickness * 2.0;

		FTransform RelevantTransform = Spline.GetWorldTransformAtSplineDistance(Boundary.ForceVisualizerSplineDistance);
		FVector Center = RelevantTransform.Location;

		TArray<FVector> TargetLocations;
		if(Boundary.Shape == EIslandEntranceSkydiveBoundarySplineShape::Box)
		{
			TargetLocations.Add(FVector::RightVector * Boundary.BaseBoxExtent.X);
			TargetLocations.Add(FVector::UpVector * Boundary.BaseBoxExtent.Y);
			TargetLocations.Add(FVector::RightVector * Boundary.BaseBoxExtent.X + FVector::UpVector * Boundary.BaseBoxExtent.Y);
		}
		else if(Boundary.Shape == EIslandEntranceSkydiveBoundarySplineShape::Cylinder)
		{
			TargetLocations.Add(FVector::RightVector * Boundary.BaseCylinderRadius);
			TargetLocations.Add(FVector::UpVector * Boundary.BaseCylinderRadius);
			TargetLocations.Add((FVector::RightVector + FVector::UpVector).GetSafeNormal() * Boundary.BaseCylinderRadius);
		}
		else
			devError("Forgot to add case");

		float Alpha;
		if(Boundary.bAnimateForceVisualizer)
			Alpha = Math::Saturate(Math::Fmod(Time::GameTimeSeconds, Boundary.ForceVisualizerAnimationDuration) / Boundary.ForceVisualizerAnimationDuration);
		else
			Alpha = Boundary.ForceVisualizerAlpha;

		for(FVector TargetLocation : TargetLocations)
		{
			FVector LocalLocation = TargetLocation * Alpha;
			FVector WorldLocation = RelevantTransform.TransformPosition(LocalLocation);
			FVector CenterToLocationDir = (WorldLocation - Center).GetSafeNormal();

			float CounterForceAlpha = Boundary.GetLocalDistanceAlphaToCenter(LocalLocation);

			DrawWireSphere(WorldLocation, SphereRadius, FLinearColor::Red, LineThickness);
			DrawArrow(WorldLocation, WorldLocation - CenterToLocationDir * (CounterForceAlpha * VectorMaxLength), FLinearColor::Red, 20.0, LineThickness);
			DrawArrow(WorldLocation, WorldLocation + CenterToLocationDir * VectorMaxLength, FLinearColor::Green, 20.0, LineThickness);
		}
	}

	void GetBoxCorners(FTransform CurrentTransform, UIslandEntranceSkydiveBoundarySplineComponent Boundary, FVector&out Point1, FVector&out Point2, FVector&out Point3, FVector&out Point4)
	{
		Point1 = CurrentTransform.TransformPosition(FVector::RightVector * Boundary.BaseBoxExtent.X - FVector::UpVector * Boundary.BaseBoxExtent.Y);
		Point2 = CurrentTransform.TransformPosition(FVector::RightVector * Boundary.BaseBoxExtent.X + FVector::UpVector * Boundary.BaseBoxExtent.Y);
		Point3 = CurrentTransform.TransformPosition(FVector::LeftVector * Boundary.BaseBoxExtent.X + FVector::UpVector * Boundary.BaseBoxExtent.Y);
		Point4 = CurrentTransform.TransformPosition(FVector::LeftVector * Boundary.BaseBoxExtent.X - FVector::UpVector * Boundary.BaseBoxExtent.Y);
	}

	void GetCylinderEdgePoints(FTransform CurrentTransform, UIslandEntranceSkydiveBoundarySplineComponent Boundary, FVector&out Point1, FVector&out Point2, FVector&out Point3, FVector&out Point4)
	{
		Point1 = CurrentTransform.TransformPosition(FVector::RightVector * Boundary.BaseCylinderRadius);
		Point2 = CurrentTransform.TransformPosition(FVector::LeftVector * Boundary.BaseCylinderRadius);
		Point3 = CurrentTransform.TransformPosition(FVector::UpVector * Boundary.BaseCylinderRadius);
		Point4 = CurrentTransform.TransformPosition(FVector::DownVector * Boundary.BaseCylinderRadius);
	}

	void DrawSquare(FVector Point1, FVector Point2, FVector Point3, FVector Point4)
	{
		DrawLine(Point1, Point2, VolumeColor, VolumeLineThickness);
		DrawLine(Point2, Point3, VolumeColor, VolumeLineThickness);
		DrawLine(Point3, Point4, VolumeColor, VolumeLineThickness);
		DrawLine(Point4, Point1, VolumeColor, VolumeLineThickness);
	}

	void DrawScaledCircle(FTransform CurrentTransform, float BaseRadius, int Segments = 16)
	{
		float Step = 360.0 / Segments;
		FVector PreviousPoint = Math::RotatorFromAxisAndAngle(FVector(1.0, 0.0, 0.0), 0.0).UpVector * BaseRadius;
		for(int i = 1; i <= Segments; i++)
		{
			FVector NewPoint = Math::RotatorFromAxisAndAngle(FVector(1.0, 0.0, 0.0), Step * i).UpVector * BaseRadius;
			DrawLine(CurrentTransform.TransformPosition(PreviousPoint), CurrentTransform.TransformPosition(NewPoint), VolumeColor, VolumeLineThickness);
			PreviousPoint = NewPoint;
		}
	}
}