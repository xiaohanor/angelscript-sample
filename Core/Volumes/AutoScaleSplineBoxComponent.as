class UAutoScaleSplineBoxComponent : UBoxComponent
{
	UPROPERTY(NotEditable)
	UHazeSplineComponent Spline;

	FVector Lowest;
	FVector Highest;

	UPROPERTY()
	float IterationDistance = 50.0;
	UPROPERTY()
	FVector BoxMargin = FVector(200.0);

	UFUNCTION(BlueprintOverride)	
	void ConstructionScript()
	{
		Spline = UHazeSplineComponent::Get(Owner);

		UpdateBoxLocation();	
		UpdateBoxExtents();
	}

	void UpdateBoxLocation()
	{
		if (Spline == nullptr)
			return;
		
		Lowest = FVector();
		Highest = FVector();
		
		int Iterations = Math::FloorToInt(Spline.GetSplineLength() / IterationDistance);
		
		for (int Index = 0, Count = Iterations; Index < Count; ++Index)
		{
			FVector SplineLocation = Spline.GetRelativeLocationAtSplineDistance(Index * IterationDistance);

			if (SplineLocation.X < Lowest.X)
				Lowest.X = SplineLocation.X;
			if (SplineLocation.Y < Lowest.Y)
				Lowest.Y = SplineLocation.Y;
			if (SplineLocation.Z < Lowest.Z)
				Lowest.Z = SplineLocation.Z;

			if (SplineLocation.X > Highest.X)
				Highest.X = SplineLocation.X;
			if (SplineLocation.Y > Highest.Y)
				Highest.Y = SplineLocation.Y;
			if (SplineLocation.Z > Highest.Z)
				Highest.Z = SplineLocation.Z;
		}

		FVector NewLocation = (Lowest + Highest) * 0.5;
		SetRelativeLocation(NewLocation);
	}

	void UpdateBoxExtents()
	{
		if (Spline == nullptr)
			return;

		FVector Extent;
		Extent.X = ((Math::Abs(Lowest.X) + Highest.X) * 0.5) + BoxMargin.X;
		Extent.Y = ((Math::Abs(Lowest.Y) + Highest.Y) * 0.5) + BoxMargin.Y;
		Extent.Z = ((Math::Abs(Lowest.Z) + Highest.Z) * 0.5) + BoxMargin.Z;

		SetBoxExtent(Extent, false);
	}
}