class USummitAdultDragonSplineFollowComponent : USceneComponent
{
	UPROPERTY(EditAnywhere, Category = "Settings")
	bool bRestrictWithinBoundaries = true;

	UPROPERTY(EditAnywhere, Category = "Settings", Meta = (EditCondition = bRestrictWithBoundaries, EditConditionHides))
	FVector2D BoundaryRadius = FVector2D(5000, 2000);

	UHazeSplineComponent SplineComp;

	// UPROPERTY(EditAnywhere)
	// bool bDrawBoundaries = true; //Temporary default to true for level editing

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		SplineComp = UHazeSplineComponent::Get(Owner);

#if EDITOR
		CookChecks::EnsureSplineCanBeUsedOutsideEditor(this, SplineComp);
#endif
	}

	FVector2D GetBoundariesAtSplinePoint(FSplinePosition SplinePosition) const
	{
		if (!SplinePosition.IsValid())
			return FVector2D::ZeroVector;

		FVector2D Boundaries = FVector2D(BoundaryRadius.X, BoundaryRadius.Y);
		Boundaries.X *= Math::Max(SplinePosition.RelativeScale3D.X, SplinePosition.RelativeScale3D.Y);
		Boundaries.Y *= SplinePosition.RelativeScale3D.Z;
		return Boundaries;
	}

	FVector2D GetBoundariesAtSplinePoint(UHazeSplineComponent Spline, int Index) const
	{
		if (Spline == nullptr)
			return FVector2D::ZeroVector;

		if (!Spline.SplinePoints.IsValidIndex(Index))
			return FVector2D::ZeroVector;

		FVector2D Boundaries = FVector2D(BoundaryRadius.X, BoundaryRadius.Y);
		float SplineDist = Spline.GetSplineDistanceAtSplinePointIndex(Index);
		FSplinePosition SplinePosition = Spline.GetSplinePositionAtSplineDistance(SplineDist);
		Boundaries.X *= SplinePosition.RelativeScale3D.Y;
		Boundaries.Y *= SplinePosition.RelativeScale3D.Z;
		return Boundaries;
	}
};

#if EDITOR
class USummitAdultDragonSplineFollowComponentVisualizer : UHazeScriptComponentVisualizer
{
	default VisualizedClass = USummitAdultDragonSplineFollowComponent;

	const FLinearColor DebugColor = FLinearColor::MakeFromHex(0xff4f84b9);

	// UFUNCTION(BlueprintOverride)
	// void VisualizeComponent(const UActorComponent Component)
	// {
	// 	USummitAdultDragonSplineFollowComponent Comp = Cast<USummitAdultDragonSplineFollowComponent>(Component);

	// 	if (!ensure((Comp != nullptr) && (Comp.GetOwner() != nullptr)))
	// 		return;

	// 	if (!Comp.bDrawBoundaries)
	// 		return;

	// 	SetRenderForeground(false);

	// 	UHazeSplineComponent SplineComp = UHazeSplineComponent::Get(Comp.Owner);
	// 	int SplinePoints = SplineComp.SplinePoints.Num();
	// 	if (SplinePoints <= 2)
	// 		return;

	// 	FSplinePosition PrevSplinePosition = Comp.GetSplinePositionAtSplinePoint(SplineComp, 0);
	// 	FVector2D PrevScale = Comp.GetBoundariesAtSplinePoint(SplineComp, 0);
	// 	DrawBox(PrevSplinePosition, PrevScale);

	// 	for (int i = 1; i < SplinePoints; ++i)
	// 	{
	// 		FVector2D Scale = Comp.GetBoundariesAtSplinePoint(SplineComp, i);
	// 		FSplinePosition SplinePosition = Comp.GetSplinePositionAtSplinePoint(SplineComp, i);

	// 		DrawBox(SplinePosition, Scale);
	// 		DrawInBetweenLines(SplinePosition, Scale, PrevSplinePosition, PrevScale);

	// 		PrevScale = Scale;
	// 		PrevSplinePosition = SplinePosition;
	// 	}
	// }

	// void DrawBox(FSplinePosition SplinePosition, FVector2D Scale)
	// {
	// 	FVector DrawExtents = FVector(1, Scale.X * 2, Scale.Y * 2);
	// 	DrawWireBox(SplinePosition.WorldLocation, DrawExtents, FQuat::MakeFromXZ(SplinePosition.WorldRotation.ForwardVector, SplinePosition.WorldRotation.UpVector), DebugColor, 10, true);
	// }

	// void DrawInBetweenLines(FSplinePosition SplinePosition, FVector2D Scale, FSplinePosition PrevSplinePosition, FVector2D PrevScale)
	// {
	// 	auto Corners = GetCorners(SplinePosition, Scale * 2);
	// 	auto PrevCorners = GetCorners(PrevSplinePosition, PrevScale * 2);

	// 	for (int i = 0; i < 4; ++i)
	// 	{
	// 		DrawLine(PrevCorners[i], Corners[i], DebugColor, 10, true);
	// 	}
	// }

	// TArray<FVector> GetCorners(FSplinePosition SplinePosition, FVector2D Scale) const
	// {
	// 	const FQuat WorldRotation = FQuat::MakeFromXZ(SplinePosition.WorldRotation.ForwardVector, SplinePosition.WorldRotation.UpVector);

	// 	TArray<FVector> Out;
	// 	FVector LeftTop = SplinePosition.WorldLocation;
	// 	LeftTop -= WorldRotation.RightVector * Scale.X;
	// 	LeftTop += WorldRotation.UpVector * Scale.Y;
	// 	Out.Add(LeftTop);

	// 	FVector RightTop = SplinePosition.WorldLocation;
	// 	RightTop += WorldRotation.RightVector * Scale.X;
	// 	RightTop += WorldRotation.UpVector * Scale.Y;
	// 	Out.Add(RightTop);

	// 	FVector LeftBottom = SplinePosition.WorldLocation;
	// 	LeftBottom -= WorldRotation.RightVector * Scale.X;
	// 	LeftBottom -= WorldRotation.UpVector * Scale.Y;
	// 	Out.Add(LeftBottom);

	// 	FVector RightBottom = SplinePosition.WorldLocation;
	// 	RightBottom += WorldRotation.RightVector * Scale.X;
	// 	RightBottom -= WorldRotation.UpVector * Scale.Y;
	// 	Out.Add(RightBottom);

	// 	return Out;
	// }
}
#endif