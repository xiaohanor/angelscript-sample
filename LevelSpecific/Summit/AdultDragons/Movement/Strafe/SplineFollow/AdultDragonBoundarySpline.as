class AAdultDragonBoundarySpline : ASplineActor
{
	UPROPERTY(DefaultComponent)
	UHazeListedActorComponent ListedActorComp;

	UPROPERTY(EditAnywhere)
	FVector2D BoundaryRadius = FVector2D(5000, 2000);

	#if EDITOR
	UPROPERTY(DefaultComponent)
	USummitAdultDragonBoundarySplineVisualizerComponent VisualizerComp;
	#endif

	bool GetIsOutsideBoundary(FVector WorldLocation, float&out DistanceToBoundary) const
	{
		auto SplinePosition = Spline.GetClosestSplinePositionToWorldLocation(WorldLocation);

		FVector2D Boundaries = GetBoundariesAtSplinePoint(SplinePosition);

		FVector SplineToLocation = WorldLocation - SplinePosition.WorldLocation;
		float DistanceToRight = SplinePosition.WorldRightVector.DotProduct(SplineToLocation);
		float DistanceUpwards = SplinePosition.WorldUpVector.DotProduct(SplineToLocation);
		float DistanceHorizontalBoundary = Math::Abs(DistanceToRight) - Boundaries.X * 2;
		float DistanceVerticalBoundary = Math::Abs(DistanceUpwards) - Boundaries.Y * 2;
		bool bIsInside = DistanceHorizontalBoundary < 0 && DistanceVerticalBoundary < 0;
		if (bIsInside)
		{
			DistanceToBoundary = 0;
			return false;
		}
		else
		{
			DistanceToBoundary = Math::Max(DistanceHorizontalBoundary, 0) + Math::Max(DistanceVerticalBoundary, 0);
			return true; 
		}
	}

	FVector GetClampedLocationWithinBoundary(FVector WorldLocation) const
	{
		auto SplinePosition = Spline.GetClosestSplinePositionToWorldLocation(WorldLocation);

		FVector2D Boundaries = GetBoundariesAtSplinePoint(SplinePosition);

		FVector SplineToWantedLocation = WorldLocation - SplinePosition.WorldLocation;

		float DistanceToRight = SplinePosition.WorldRightVector.DotProduct(SplineToWantedLocation);
		DistanceToRight = Math::Clamp(DistanceToRight, -Boundaries.X * 2.0, Boundaries.X * 2.0);

		float DistanceUpwards = SplinePosition.WorldUpVector.DotProduct(SplineToWantedLocation);
		DistanceUpwards = Math::Clamp(DistanceUpwards, -Boundaries.Y * 2.0, Boundaries.Y * 2.0);

		float DistanceForwards = SplinePosition.WorldForwardVector.DotProduct(SplineToWantedLocation);
		FVector ClampedLocation = SplinePosition.WorldLocation + SplinePosition.WorldForwardVector * DistanceForwards + SplinePosition.WorldRightVector * DistanceToRight + SplinePosition.WorldUpVector * DistanceUpwards;

		TEMPORAL_LOG(this)
			.DirectionalArrow("Distance To Right", SplinePosition.WorldLocation, SplinePosition.WorldRightVector * DistanceToRight, 50, 80, FLinearColor::Green)
			.DirectionalArrow("Distance Upwards", SplinePosition.WorldLocation, SplinePosition.WorldUpVector * DistanceUpwards, 50, 80, FLinearColor::Blue)
			.Box("Boundary", SplinePosition.WorldLocation, FVector(50, Boundaries.X * 2.0, Boundaries.Y * 2.0), SplinePosition.WorldRotation.Rotator(), FLinearColor::Red, 10)
			.Sphere("Target Location", ClampedLocation, 5000, FLinearColor::LucBlue, 20)
			.Sphere("Spline Location", SplinePosition.WorldLocation, 5000, FLinearColor::Yellow, 20);

		return ClampedLocation;
	}

	FVector2D GetBoundariesAtSplinePoint(FSplinePosition SplinePosition) const
	{
		FVector2D DrawExtents = FVector2D(BoundaryRadius.X, BoundaryRadius.Y);
		DrawExtents.X *= SplinePosition.RelativeScale3D.Y;
		DrawExtents.Y *= SplinePosition.RelativeScale3D.Z;
		return DrawExtents;
	}
};

#if EDITOR
class UAdultDragonBoundarySplineActorMenuExtension : UScriptActorMenuExtension
{
	// Specify one or more classes for which the menu options show
	default SupportedClasses.Add(ASplineActor);

	UFUNCTION(BlueprintOverride)
	bool ShouldExtend() const
	{
		if (!World.IsEditorWorld())
			return false;

		if (!World.Name.PlainNameString.Contains("Summit", ESearchCase::IgnoreCase, ESearchDir::FromStart))
			return false;

		return true;
	}
	// Every function with the CallInEditor specifier will become a context menu option
	UFUNCTION(CallInEditor)
	void GenerateBoundarySplineFromSelected()
	{
		TArray<AActor> SelectedActors = Editor::SelectedActors;
		TArray<FHazeSplinePoint> SplinePoints;

		for (auto Actor : SelectedActors)
		{
			auto SplineActor = Cast<ASplineActor>(Actor);
			auto Spline = SplineActor.Spline;
			for (int i = 0; i < Spline.SplinePoints.Num(); i++)
			{
				auto Point = Spline.SplinePoints[i];
				Point.RelativeLocation = Spline.WorldTransform.InverseTransformPosition(SplineActor.ActorTransform.TransformPosition(Point.RelativeLocation));
				Point.RelativeScale3D = Point.RelativeScale3D / SplineActor.ActorTransform.Scale3D.ComponentMax(FVector(0.001, 0.001, 0.001));
				Point.RelativeRotation = Spline.WorldTransform.InverseTransformRotation(SplineActor.ActorTransform.TransformRotation(Point.RelativeRotation));
				Point.ArriveTangent = Spline.WorldTransform.InverseTransformVector(SplineActor.ActorTransform.TransformVector(Point.ArriveTangent));
				Point.LeaveTangent = Spline.WorldTransform.InverseTransformVector(SplineActor.ActorTransform.TransformVector(Point.LeaveTangent));
				SplinePoints.Add(Point);
			}
		}

		AAdultDragonBoundarySpline BoundarySpline = SpawnActor(AAdultDragonBoundarySpline, SelectedActors[0].ActorLocation, SelectedActors[0].ActorRotation, n"AdultDragonBoundarySpline", true, SelectedActors[0].Level);
		BoundarySpline.Spline.SplinePoints = SplinePoints;
	}
}

class USummitAdultDragonBoundarySplineVisualizerComponent : UActorComponent
{
}

class USummitAdultDragonBoundarySplineVisualizer : UHazeScriptComponentVisualizer
{
	default VisualizedClass = USummitAdultDragonBoundarySplineVisualizerComponent;

	const FLinearColor DebugColor = FLinearColor::MakeFromHex(0xffaeb94f);

	UFUNCTION(BlueprintOverride)
	void VisualizeComponent(const UActorComponent Component)
	{
		USummitAdultDragonBoundarySplineVisualizerComponent Comp = Cast<USummitAdultDragonBoundarySplineVisualizerComponent>(Component);

		if (Comp == nullptr)
			return;

		AAdultDragonBoundarySpline Spline = Cast<AAdultDragonBoundarySpline>(Comp.Owner);
		
		UHazeSplineComponent SplineComp = Spline.Spline;
		int SplinePoints = SplineComp.SplinePoints.Num();
		if (SplinePoints <= 2)
			return;
		

		float IntervalDistance = 20000;
		float CurrentDistance = IntervalDistance;
		while (CurrentDistance < SplineComp.SplineLength)
		{
			FSplinePosition PrevSplinePosition = SplineComp.GetSplinePositionAtSplineDistance(CurrentDistance - IntervalDistance);
			FVector2D PrevScale = Spline.GetBoundariesAtSplinePoint(PrevSplinePosition);
			DrawBox(PrevSplinePosition, PrevScale);

			FSplinePosition SplinePosition = SplineComp.GetSplinePositionAtSplineDistance(CurrentDistance);
			FVector2D Scale = Spline.GetBoundariesAtSplinePoint(SplinePosition);
			DrawBox(SplinePosition, Scale);
			DrawInBetweenLines(SplinePosition, Scale, PrevSplinePosition, PrevScale);
			CurrentDistance += IntervalDistance;
		}
	}

	void DrawBox(FSplinePosition SplinePosition, FVector2D Scale)
	{
		FVector DrawExtents = FVector(1, Scale.X * 2, Scale.Y * 2);
		DrawWireBox(SplinePosition.WorldLocation, DrawExtents, FQuat::MakeFromXZ(SplinePosition.WorldRotation.ForwardVector, SplinePosition.WorldRotation.UpVector), DebugColor, 300, false);
	}

	void DrawInBetweenLines(FSplinePosition SplinePosition, FVector2D Scale, FSplinePosition PrevSplinePosition, FVector2D PrevScale)
	{
		auto Corners = GetCorners(SplinePosition, Scale * 2);
		auto PrevCorners = GetCorners(PrevSplinePosition, PrevScale * 2);

		for (int i = 0; i < 4; ++i)
		{
			DrawLine(PrevCorners[i], Corners[i], DebugColor, 300, false);
		}
	}

	TArray<FVector> GetCorners(FSplinePosition SplinePosition, FVector2D Scale) const
	{
		const FQuat WorldRotation = FQuat::MakeFromXZ(SplinePosition.WorldRotation.ForwardVector, SplinePosition.WorldRotation.UpVector);

		TArray<FVector> Out;
		FVector LeftTop = SplinePosition.WorldLocation;
		LeftTop -= WorldRotation.RightVector * Scale.X;
		LeftTop += WorldRotation.UpVector * Scale.Y;
		Out.Add(LeftTop);

		FVector RightTop = SplinePosition.WorldLocation;
		RightTop += WorldRotation.RightVector * Scale.X;
		RightTop += WorldRotation.UpVector * Scale.Y;
		Out.Add(RightTop);

		FVector LeftBottom = SplinePosition.WorldLocation;
		LeftBottom -= WorldRotation.RightVector * Scale.X;
		LeftBottom -= WorldRotation.UpVector * Scale.Y;
		Out.Add(LeftBottom);

		FVector RightBottom = SplinePosition.WorldLocation;
		RightBottom += WorldRotation.RightVector * Scale.X;
		RightBottom -= WorldRotation.UpVector * Scale.Y;
		Out.Add(RightBottom);

		return Out;
	}
}
#endif