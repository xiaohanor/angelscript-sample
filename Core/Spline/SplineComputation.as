/*
 _______________________________________
/ OBS!                                  \
|                                       |
| This code is duplicated between       |
| HazeSplineComputationStatics.h and    |
| SplineComputation.as.                 |
|                                       |
| Normally only the C++ version is in   |
| use, the AS one can be swapped in for |
| rapid iteration if necessary.         |
|                                       |
| When editing this, make sure to also  |
\ update the other version!             /
 ---------------------------------------
        \   ^__^
         \  (oo)\_______
            (__)\       )\/\
                ||----w |
                ||     ||
*/

namespace SplineComputation_AS
{

void ComputeSpline(FHazeSplineSettings Settings, TArray<FHazeSplinePoint>& InPoints, FHazeComputedSpline& OutSpline)
{
	// Reset computed spline
	OutSpline.Points.Reset();
	OutSpline.Segments.Reset();
	OutSpline.Samples_SplineAlpha.Reset();
	OutSpline.Samples_SegmentAlpha.Reset();
	OutSpline.Samples_SegmentIndex.Reset();
	OutSpline.SplineLength = 0.0;

	int PointCount = InPoints.Num();

	// Add computed points
	for (const FHazeSplinePoint& PointParams : InPoints)
	{
		FHazeComputedSplinePoint Point;
		Point.PointIndex = OutSpline.Points.Num();
		Point.RelativeLocation = PointParams.RelativeLocation;
		Point.RelativeRotation = PointParams.RelativeRotation;
		Point.RelativeScale3D = PointParams.RelativeScale3D;
		Point.ArriveTangent = PointParams.ArriveTangent;
		Point.LeaveTangent = PointParams.LeaveTangent;

		OutSpline.Points.Add(Point);
	}

	// Auto Tangents
	for (int PointIndex = 0; PointIndex < PointCount; ++PointIndex)
	{
		FHazeSplinePoint& InputPoint = InPoints[PointIndex];
		FHazeComputedSplinePoint& Point = OutSpline.Points[PointIndex];

		if (PointIndex == 0 && !Settings.bClosedLoop)
		{
			if (!InputPoint.bOverrideTangent)
			{
				if (PointCount > 2)
				{
					FVector Current = OutSpline.Points[PointIndex].RelativeLocation;
					FVector Next = OutSpline.Points[PointIndex+1].RelativeLocation;
					FVector NextNext = OutSpline.Points[PointIndex+2].RelativeLocation;

					Point.LeaveTangent = GetAutoTangentFromLocations(Current, Next, NextNext);

					float PointDistance = Current.Distance(Next) * 0.25;
					FVector TangentLocation = Next + Point.LeaveTangent * PointDistance;

					Point.LeaveTangent = TangentLocation - Current;
					Point.ArriveTangent = Point.LeaveTangent;
				}
				else if (PointCount > 1)
				{
					FVector Current = OutSpline.Points[PointIndex].RelativeLocation;
					FVector Next = OutSpline.Points[PointIndex+1].RelativeLocation;

					GetUnrealAutoTangent(
						Current,
						Current,
						Next,
						0.0, 
						Point.LeaveTangent,
					);
					Point.ArriveTangent = Point.LeaveTangent;
				}
			}

			if (PointCount > 1)
			{
				FQuat::CalcTangents(
					OutSpline.Points[PointIndex].RelativeRotation,
					OutSpline.Points[PointIndex].RelativeRotation,
					OutSpline.Points[PointIndex+1].RelativeRotation,
					0.0, 
					Point.LeaveTangent_Rotation,
				);
				Point.ArriveTangent_Rotation = Point.LeaveTangent_Rotation;

				GetUnrealAutoTangent(
					OutSpline.Points[PointIndex].RelativeScale3D,
					OutSpline.Points[PointIndex].RelativeScale3D,
					OutSpline.Points[PointIndex+1].RelativeScale3D,
					0.0, 
					Point.LeaveTangent_Scale,
				);
				Point.ArriveTangent_Scale = Point.LeaveTangent_Scale;
			}
		}
		else if (PointIndex == PointCount - 1 && !Settings.bClosedLoop)
		{
			if (!InputPoint.bOverrideTangent)
			{
				if (PointCount > 2)
				{
					FVector Current = OutSpline.Points[PointIndex].RelativeLocation;
					FVector Previous = OutSpline.Points[PointIndex-1].RelativeLocation;
					FVector PreviousPrevious = OutSpline.Points[PointIndex-2].RelativeLocation;

					Point.ArriveTangent = GetAutoTangentFromLocations(Current, Previous, PreviousPrevious);

					float PointDistance = Current.Distance(Previous) * 0.25;
					FVector TangentLocation = Previous + Point.ArriveTangent * PointDistance;

					Point.ArriveTangent = -(TangentLocation - Current);
					Point.LeaveTangent = Point.ArriveTangent;
				}
				else if (PointCount > 1)
				{
					FVector Current = OutSpline.Points[PointIndex].RelativeLocation;
					FVector Previous = OutSpline.Points[PointIndex-1].RelativeLocation;

					GetUnrealAutoTangent(
						Previous,
						Current,
						Current,
						0.0, 
						Point.LeaveTangent,
					);
					Point.ArriveTangent = Point.LeaveTangent;
				}
			}

			if (PointCount > 1)
			{
				FQuat::CalcTangents(
					OutSpline.Points[PointIndex-1].RelativeRotation,
					OutSpline.Points[PointIndex].RelativeRotation,
					OutSpline.Points[PointIndex].RelativeRotation,
					0.0, 
					Point.LeaveTangent_Rotation,
				);
				Point.ArriveTangent_Rotation = Point.LeaveTangent_Rotation;

				GetUnrealAutoTangent(
					OutSpline.Points[PointIndex-1].RelativeScale3D,
					OutSpline.Points[PointIndex].RelativeScale3D,
					OutSpline.Points[PointIndex].RelativeScale3D,
					0.0, 
					Point.LeaveTangent_Scale,
				);
				Point.ArriveTangent_Scale = Point.LeaveTangent_Scale;
			}
		}
		else
		{
			int PreviousIndex = (PointIndex - 1 + PointCount) % PointCount;
			int NextIndex = (PointIndex + 1) % PointCount;

			// Get spline positions
			if (!InputPoint.bOverrideTangent)
			{
				FVector Previous = OutSpline.Points[PreviousIndex].RelativeLocation;
				FVector Current = OutSpline.Points[PointIndex].RelativeLocation;
				FVector Next = OutSpline.Points[NextIndex].RelativeLocation;

				// Calculate tangent angles
				Point.LeaveTangent = GetAutoTangentFromLocations(Previous, Current, Next);

				// Scale tangents to prevent over/under-shooting
				float DistanceToPrevious = Current.Distance(Previous);
				float DistanceToNext = Current.Distance(Next);
				
				Point.ArriveTangent = -Point.LeaveTangent * DistanceToPrevious;
				Point.LeaveTangent = -Point.LeaveTangent * DistanceToNext;
			}

			FQuat::CalcTangents(
				OutSpline.Points[PreviousIndex].RelativeRotation,
				OutSpline.Points[PointIndex].RelativeRotation,
				OutSpline.Points[NextIndex].RelativeRotation,
				0.0,
				Point.LeaveTangent_Rotation,
			);
			Point.LeaveTangent_Rotation *= 0.5;
			Point.ArriveTangent_Rotation = Point.LeaveTangent_Rotation;

			GetUnrealAutoTangent(
				OutSpline.Points[PreviousIndex].RelativeScale3D,
				OutSpline.Points[PointIndex].RelativeScale3D,
				OutSpline.Points[NextIndex].RelativeScale3D,
				0.0, 
				Point.LeaveTangent_Scale,
			);
			Point.LeaveTangent_Scale *= 0.5;
			Point.ArriveTangent_Scale = Point.LeaveTangent_Scale;
		}

		// If any tangents are zero, make them straight instead
		if (Point.ArriveTangent.IsZero())
		{
			if (PointIndex > 0)
				Point.ArriveTangent = Point.RelativeLocation - InPoints[PointIndex - 1].RelativeLocation;
			else if (Settings.bClosedLoop)
				Point.ArriveTangent = Point.RelativeLocation - InPoints.Last().RelativeLocation;
			else if (PointCount >= 2)
				Point.ArriveTangent = InPoints[1].RelativeLocation - Point.RelativeLocation;
			else
				Point.ArriveTangent = -FVector::ForwardVector;
		}

		if (Point.LeaveTangent.IsZero())
		{
			if (PointIndex < PointCount - 1)
				Point.LeaveTangent = InPoints[PointIndex + 1].RelativeLocation - Point.RelativeLocation;
			else if (Settings.bClosedLoop)
				Point.LeaveTangent = InPoints[0].RelativeLocation - Point.RelativeLocation;
			else if (PointCount >= 2)
				Point.LeaveTangent = Point.RelativeLocation - InPoints[InPoints.Num() - 2].RelativeLocation;
			else
				Point.LeaveTangent = FVector::ForwardVector;
		}
	}

	// Add a synthetic point in case of looping
	if (Settings.bClosedLoop && OutSpline.Points.Num() >= 2)
	{
		FHazeComputedSplinePoint LoopedPoint = OutSpline.Points[0];
		OutSpline.Points.Add(LoopedPoint);
		PointCount += 1;
	}

	// Add computed segments
	for (int PointIndex = 0; PointIndex < PointCount-1; ++PointIndex)
	{
		FHazeComputedSplineSegment Segment;
		Segment.StartPointIndex = PointIndex;
		Segment.EndPointIndex = PointIndex+1;

		OutSpline.Segments.Add(Segment);
	}

	int SegmentCount = OutSpline.Segments.Num();

	// Figure out how many samples we actually should generate
	int TotalWantedSampleCount = 0;
	for (int SegmentIndex = 0; SegmentIndex < SegmentCount; ++SegmentIndex)
	{
		FHazeComputedSplineSegment& Segment = OutSpline.Segments[SegmentIndex];
		FHazeComputedSplinePoint& StartPoint = OutSpline.Points[Segment.StartPointIndex];
		FHazeComputedSplinePoint& EndPoint = OutSpline.Points[Segment.EndPointIndex];

		// Use first target estimate
		int WantedSamples = Settings.MinSamplesPerSegment;

		// See if our length estimate wants more samples
		float EstimatedLength = GetSegmentLength(StartPoint, EndPoint, 1.0);
		int WantedLengthSamples = Math::CeilToInt(EstimatedLength / Settings.TargetSampleInterval);
		if (WantedLengthSamples > WantedSamples)
			WantedSamples = WantedLengthSamples;

		// Record how many samples we want
		Segment.SampleCount = WantedSamples;
		TotalWantedSampleCount += WantedSamples;
	}

	// Generate samples for each segment
	float SampleFactor = 1.0;
	if (TotalWantedSampleCount > Settings.MaxTotalSamples)
		SampleFactor = float(Settings.MaxTotalSamples) / float(TotalWantedSampleCount);

	int SampleCount = 0;
	TArray<float> Samples_SplineDistance;

	// Add the first sample that starts at the first point in the spline
	if (SegmentCount != 0)
	{
		OutSpline.Samples_SegmentAlpha.Add(0.f);
		OutSpline.Samples_SegmentIndex.Add(0);
		Samples_SplineDistance.Add(0.0);

		OutSpline.Points[0].SplineDistance = 0.0;
		OutSpline.Points[0].SampleIndex = 0;

		SampleCount += 1;
	}

	float SplineDistance = 0.0;
	for (int SegmentIndex = 0; SegmentIndex < SegmentCount; ++SegmentIndex)
	{
		FHazeComputedSplineSegment& Segment = OutSpline.Segments[SegmentIndex];
		FHazeComputedSplinePoint& StartPoint = OutSpline.Points[Segment.StartPointIndex];
		FHazeComputedSplinePoint& EndPoint = OutSpline.Points[Segment.EndPointIndex];

		Segment.StartSampleIndex = SampleCount-1;
		Segment.StartSplineDistance = SplineDistance;
		Segment.Bounds = FBox(StartPoint.RelativeLocation, StartPoint.RelativeLocation);

		int SegSampleCount = Math::Max(Settings.MinSamplesPerSegment, Math::FloorToInt(float(Segment.SampleCount) * SampleFactor));

		FVector SegmentDelta = (EndPoint.RelativeLocation - StartPoint.RelativeLocation);
		Segment.LinearDistance = SegmentDelta.Size();
		if (Segment.LinearDistance > 0.0)
			Segment.Direction = SegmentDelta / Segment.LinearDistance;
		else
			Segment.Direction = FVector::ZeroVector;

		// If a segment's tangents are both on the line between the two spline points,
		// that means the segment will just be a straight line. In that case, we don't need to
		// generate more than 1 sample point, there's nothing to approximate.
		const bool bSegmentIsStraightLine =
			Math::Abs(StartPoint.LeaveTangent.GetSafeNormal().DotProduct(Segment.Direction)) >= 0.9999
			&& Math::Abs(EndPoint.ArriveTangent.GetSafeNormal().DotProduct(Segment.Direction)) >= 0.9999
			&& StartPoint.LeaveTangent.Equals(EndPoint.ArriveTangent);
		if (bSegmentIsStraightLine)
			SegSampleCount = 1;

		float SampleAlphaInterval = 1.0 / float(SegSampleCount);
		float StartSplineDistance = SplineDistance;
		for (int SegSampleIndex = 0; SegSampleIndex < SegSampleCount; ++SegSampleIndex)
		{
			float Alpha = SampleAlphaInterval * float(SegSampleIndex + 1);

			// TODO: Optimize this so the Coeffs in GetSegmentLength aren't recalculated each time?
			SplineDistance = StartSplineDistance + Math::Max(GetSegmentLength(StartPoint, EndPoint, Alpha), 0.01);

			FVector SampleRelativeLocation = Math::CubicInterp(
				StartPoint.RelativeLocation,
				StartPoint.LeaveTangent,
				EndPoint.RelativeLocation,
				EndPoint.ArriveTangent,
				Alpha);

			Samples_SplineDistance.Add(SplineDistance);
			OutSpline.Samples_SegmentAlpha.Add(float32(Alpha));
			OutSpline.Samples_SegmentIndex.Add(uint16(SegmentIndex));

			// Add sample location to segment bounds
			Segment.Bounds += SampleRelativeLocation;
		}

		SampleCount += SegSampleCount;
		Segment.BoundsRadius = Segment.Bounds.Extent.Size();
		Segment.EndSplineDistance = SplineDistance;
		Segment.SampleCount = SegSampleCount+1;

		EndPoint.SplineDistance = SplineDistance;
		EndPoint.SampleIndex = Segment.StartSampleIndex + Segment.SampleCount - 1;
	}

	// Figure out the final spline data
	OutSpline.SplineLength = SplineDistance;
	OutSpline.Samples_SplineAlpha.SetNumZeroed(Samples_SplineDistance.Num());
	for (int i = 0, Count = Samples_SplineDistance.Num(); i < Count; ++i)
		OutSpline.Samples_SplineAlpha[i] = float32(Samples_SplineDistance[i] / SplineDistance);

	// Merge all segment bounds into the full spline bounds
	if (SegmentCount > 0)
	{
		OutSpline.Bounds = OutSpline.Segments[0].Bounds;
		for (int i = 1; i < SegmentCount; ++i)
			OutSpline.Bounds += OutSpline.Segments[i].Bounds;
		OutSpline.BoundsRadius = OutSpline.Bounds.Extent.Size();
	}
}

void ComputeAutoTangentForPoint(FHazeSplineSettings Settings, TArray<FHazeSplinePoint> InPoints, int PointIndex, FVector& OutArriveTangent, FVector& OutLeaveTangent)
{
	const FHazeSplinePoint& InputPoint = InPoints[PointIndex];
	int PointCount = InPoints.Num();
	if (PointIndex == 0 && !Settings.bClosedLoop)
	{
		if (PointCount > 2)
		{
			FVector Current = InPoints[PointIndex].RelativeLocation;
			FVector Next = InPoints[PointIndex+1].RelativeLocation;
			FVector NextNext = InPoints[PointIndex+2].RelativeLocation;

			OutLeaveTangent = GetAutoTangentFromLocations(Current, Next, NextNext);
			float Distance = Current.Distance(Next) * 0.25;
			FVector TangentLocation = Next + OutLeaveTangent * Distance;

			OutLeaveTangent = TangentLocation - Current;
			OutArriveTangent = OutLeaveTangent;
		}
		else if (PointCount > 1)
		{
			FVector Current = InPoints[PointIndex].RelativeLocation;
			FVector Next = InPoints[PointIndex+1].RelativeLocation;

			GetUnrealAutoTangent(
				Current,
				Current,
				Next,
				0.0, 
				OutLeaveTangent,
			);
			OutArriveTangent = OutLeaveTangent;
		}
	}
	else if (PointIndex == PointCount - 1 && !Settings.bClosedLoop)
	{
		if (PointCount > 2)
		{
			FVector Current = InPoints[PointIndex].RelativeLocation;
			FVector Previous = InPoints[PointIndex-1].RelativeLocation;
			FVector PreviousPrevious = InPoints[PointIndex-2].RelativeLocation;

			OutArriveTangent = GetAutoTangentFromLocations(Current, Previous, PreviousPrevious);
			float dist = Current.Distance(Previous) * 0.25;
			FVector TangentLocation = Previous + OutArriveTangent * dist;

			OutArriveTangent = -(TangentLocation - Current);
			OutLeaveTangent = OutArriveTangent;
		}
		else if (PointCount > 1)
		{
			FVector Current = InPoints[PointIndex].RelativeLocation;
			FVector Previous = InPoints[PointIndex-1].RelativeLocation;

			GetUnrealAutoTangent(
				Previous,
				Current,
				Current,
				0.0, 
				OutLeaveTangent,
			);
			OutArriveTangent = OutLeaveTangent;
		}
	}
	else
	{
		int PreviousIndex = (PointIndex - 1 + PointCount) % PointCount;
		int NextIndex = (PointIndex + 1) % PointCount;

		// Get spline positions
		FVector Previous = InPoints[PreviousIndex].RelativeLocation;
		FVector Current = InPoints[PointIndex].RelativeLocation;
		FVector Next = InPoints[NextIndex].RelativeLocation;

		// Calculate tangent angles
		OutLeaveTangent = GetAutoTangentFromLocations(Previous, Current, Next);

		// Scale tangents to prevent over/under-shooting
		float DistanceToPrevious = Current.Distance(Previous);
		float DistanceToNext = Current.Distance(Next);
		
		OutArriveTangent = -OutLeaveTangent * DistanceToPrevious;
		OutLeaveTangent = -OutLeaveTangent * DistanceToNext;
	}
}

TArray<FVector2D> MakeLegendreGaussCoefficients()
{
	TArray<FVector2D> Coefficients;
	Coefficients.Add(FVector2D(0.0, 0.5688889));
	Coefficients.Add(FVector2D(-0.5384693, 0.47862867));
	Coefficients.Add(FVector2D(0.5384693, 0.47862867));
	Coefficients.Add(FVector2D(-0.90617985, 0.23692688));
	Coefficients.Add(FVector2D(0.90617985, 0.23692688));
	return Coefficients;
}

const TArray<FVector2D> LegendreGaussCoefficients = MakeLegendreGaussCoefficients();

float GetSegmentLength(const FHazeComputedSplinePoint& StartPoint, const FHazeComputedSplinePoint& EndPoint, float Alpha)
{
	FVector P0 = StartPoint.RelativeLocation;
	FVector T0 = StartPoint.LeaveTangent;
	FVector P1 = EndPoint.RelativeLocation;
	FVector T1 = EndPoint.ArriveTangent;

	FVector Coeff1 = ((P0 - P1) * 2.0 + T0 + T1) * 3.0;
	FVector Coeff2 = (P1 - P0) * 6.0 - T0 * 4.0 - T1 * 2.0;
	FVector Coeff3 = T0;

	const float Halfway = Alpha * 0.5;

	float Length = 0.0;
	for (const FVector2D& LegendreGaussCoefficient : LegendreGaussCoefficients)
	{
		float SampleAlpha = Halfway * (1.0 + LegendreGaussCoefficient.X);
		FVector Derivative = ((Coeff1 * SampleAlpha + Coeff2) * SampleAlpha + Coeff3);
		Length += Derivative.Size() * LegendreGaussCoefficient.Y;
	}
	Length *= Halfway;

	return Length;
}

FVector GetAutoTangentFromLocations(FVector Previous, FVector Current, FVector Next)
{
	FVector Average = (Previous + Next) * 0.5;
	FVector Delta = Current - Average;
	FVector LeaveTangentLocation = Next + Delta;

	FVector LeaveTangent = Current - LeaveTangentLocation;
	LeaveTangent.Normalize();

	return LeaveTangent;
}

void GetUnrealAutoTangent(FVector PrevP, FVector P, FVector NextP, float Tension, FVector& OutTan )
{
	OutTan = ( (P - PrevP) + (NextP - P) ) * (1.0 - Tension);
}

FVector GetRelativeLocationAtSegmentAlpha(FHazeComputedSpline Spline, int SegmentIndex, float Alpha)
{
	if (!Spline.Segments.IsValidIndex(SegmentIndex))
		return FVector::ZeroVector;

	const FHazeComputedSplineSegment& Segment = Spline.Segments[SegmentIndex];
	const FHazeComputedSplinePoint& PrevPoint = Spline.Points[Segment.StartPointIndex];
	const FHazeComputedSplinePoint& NextPoint = Spline.Points[Segment.EndPointIndex];

	return Math::CubicInterp(
		PrevPoint.RelativeLocation,
		PrevPoint.LeaveTangent,
		NextPoint.RelativeLocation,
		NextPoint.ArriveTangent,
		Alpha);
}

FVector GetRelativeTangentAtSegmentAlpha(FHazeComputedSpline Spline, int SegmentIndex, float Alpha)
{
	if (!Spline.Segments.IsValidIndex(SegmentIndex))
		return FVector::ZeroVector;

	const FHazeComputedSplineSegment& Segment = Spline.Segments[SegmentIndex];
	const FHazeComputedSplinePoint& PrevPoint = Spline.Points[Segment.StartPointIndex];
	const FHazeComputedSplinePoint& NextPoint = Spline.Points[Segment.EndPointIndex];

	if (Alpha <= 0.0)
		return PrevPoint.LeaveTangent;
	else if (Alpha >= 1.0)
		return NextPoint.ArriveTangent;

	return Math::CubicInterpDerivative(
		PrevPoint.RelativeLocation,
		PrevPoint.LeaveTangent,
		NextPoint.RelativeLocation,
		NextPoint.ArriveTangent,
		Alpha);
}

FQuat GetRelativeRotationAtSegmentAlpha(FHazeComputedSpline Spline, int SegmentIndex, float Alpha)
{
	if (!Spline.Segments.IsValidIndex(SegmentIndex))
		return FQuat::Identity;

	FVector Tangent = GetRelativeTangentAtSegmentAlpha(Spline, SegmentIndex, Alpha);
	Tangent = Tangent.GetSafeNormal();

	const FHazeComputedSplineSegment& Segment = Spline.Segments[SegmentIndex];
	const FHazeComputedSplinePoint& PrevPoint = Spline.Points[Segment.StartPointIndex];
	const FHazeComputedSplinePoint& NextPoint = Spline.Points[Segment.EndPointIndex];

	FQuat RotationInSpline = Math::CubicInterp(
		PrevPoint.RelativeRotation,
		PrevPoint.LeaveTangent_Rotation,
		NextPoint.RelativeRotation,
		NextPoint.ArriveTangent_Rotation,
		Alpha);
	RotationInSpline.Normalize();

	FVector UpVector = RotationInSpline.RotateVector(FVector::UpVector);

	// If the up vector and the tangent are linearly dependent, then
	// we have a problem, because we can't create a consistent rotation frame.
	// We pick the global up vector or forward vector, so it's always consistent.
	if (Math::Abs(UpVector.DotProduct(Tangent)) >= 0.999)
	{
		if (Math::Abs(FVector::UpVector.DotProduct(Tangent)) >= 0.999)
			UpVector = FVector::ForwardVector;
		else
			UpVector = FVector::UpVector;
	}

	return FQuat::MakeFromXZ(Tangent, UpVector);
}

FVector GetRelativeScale3DAtSegmentAlpha(FHazeComputedSpline Spline, int SegmentIndex, float Alpha)
{
	if (!Spline.Segments.IsValidIndex(SegmentIndex))
		return FVector::OneVector;

	const FHazeComputedSplineSegment& Segment = Spline.Segments[SegmentIndex];
	const FHazeComputedSplinePoint& PrevPoint = Spline.Points[Segment.StartPointIndex];
	const FHazeComputedSplinePoint& NextPoint = Spline.Points[Segment.EndPointIndex];

	return Math::CubicInterp(
		PrevPoint.RelativeScale3D,
		PrevPoint.LeaveTangent_Scale,
		NextPoint.RelativeScale3D,
		NextPoint.ArriveTangent_Scale,
		Alpha);
}

FTransform GetRelativeTransformAtSegmentAlpha(FHazeComputedSpline Spline, int SegmentIndex, float Alpha)
{
	if (!Spline.Segments.IsValidIndex(SegmentIndex))
		return FTransform::Identity;

	const FHazeComputedSplineSegment& Segment = Spline.Segments[SegmentIndex];
	const FHazeComputedSplinePoint& PrevPoint = Spline.Points[Segment.StartPointIndex];
	const FHazeComputedSplinePoint& NextPoint = Spline.Points[Segment.EndPointIndex];

	FVector Tangent;
	if (Alpha <= 0.0)
	{
		Tangent = PrevPoint.LeaveTangent.GetSafeNormal();
	}
	else if (Alpha >= 1.0)
	{
		Tangent = NextPoint.ArriveTangent.GetSafeNormal();
	}
	else
	{
		Tangent = Math::CubicInterpDerivative(
			PrevPoint.RelativeLocation,
			PrevPoint.LeaveTangent,
			NextPoint.RelativeLocation,
			NextPoint.ArriveTangent,
			Alpha).GetSafeNormal();
	}

	FQuat RotationInSpline = Math::CubicInterp(
		PrevPoint.RelativeRotation,
		PrevPoint.LeaveTangent_Rotation,
		NextPoint.RelativeRotation,
		NextPoint.ArriveTangent_Rotation,
		Alpha);
	RotationInSpline.Normalize();

	FVector UpVector = RotationInSpline.RotateVector(FVector::UpVector);

	// If the up vector and the tangent are linearly dependent, then
	// we have a problem, because we can't create a consistent rotation frame.
	// We pick the global up vector or forward vector, so it's always consistent.
	if (Math::Abs(UpVector.DotProduct(Tangent)) >= 0.999)
	{
		if (Math::Abs(FVector::UpVector.DotProduct(Tangent)) >= 0.999)
			UpVector = FVector::ForwardVector;
		else
			UpVector = FVector::UpVector;
	}

	return FTransform(
		FQuat::MakeFromXZ(Tangent, UpVector),
		Math::CubicInterp(
			PrevPoint.RelativeLocation,
			PrevPoint.LeaveTangent,
			NextPoint.RelativeLocation,
			NextPoint.ArriveTangent,
			Alpha),
		Math::CubicInterp(
			PrevPoint.RelativeScale3D,
			PrevPoint.LeaveTangent_Scale,
			NextPoint.RelativeScale3D,
			NextPoint.ArriveTangent_Scale,
			Alpha),
	);
}

void GetSegmentAlphaAtSplineDistance(FHazeComputedSpline Spline, float SplineDistance, int& OutSegmentIndex, float& OutAlpha)
{
	// Before start of spline
	if (SplineDistance <= 0.0)
	{
		OutSegmentIndex = 0;
		OutAlpha = 0.0;
		return;
	}

	// After end of spline
	if (SplineDistance >= Spline.SplineLength)
	{
		OutSegmentIndex = Spline.Segments.Num() - 1;
		OutAlpha = 1.0;
		return;
	}

	// Binary search for the sample point interval closest to the spline position
	float32 FindSplineAlpha = float32(SplineDistance / Spline.SplineLength);

	int32 SearchEnd = Spline.Samples_SplineAlpha.Num() - 1;
	if (SearchEnd <= 0)
	{
		OutSegmentIndex = 0;
		OutAlpha = 0.0;
		return;
	}

	int32 SearchStart = 0;
	while (SearchStart != SearchEnd)
	{
		// TODO: Should we choose a pivot using a heuristic based on the amount of samples vs spline position?
		int32 PivotIndex = SearchStart + ((SearchEnd - SearchStart) >> 1);

		float32 LeftSampleSplineAlpha = Spline.Samples_SplineAlpha[PivotIndex];
		float32 RightSampleSplineAlpha = Spline.Samples_SplineAlpha[PivotIndex + 1];

		if (LeftSampleSplineAlpha <= FindSplineAlpha)
		{
			if (RightSampleSplineAlpha >= FindSplineAlpha)
			{
				uint16 LeftSampleSegmentIndex = Spline.Samples_SegmentIndex[PivotIndex];
				uint16 RightSampleSegmentIndex = Spline.Samples_SegmentIndex[PivotIndex + 1];

				if (LeftSampleSegmentIndex != RightSampleSegmentIndex)
				{
					// The spline segment changed between these two samples, so take it as the start of the right segment
					OutSegmentIndex = RightSampleSegmentIndex;

					float RangeInSegmentAlphaSpace = Spline.Samples_SegmentAlpha[PivotIndex + 1];
					float RangeInSplineAlphaSpace = (RightSampleSplineAlpha - LeftSampleSplineAlpha);
					float PctInSplineAlphaSpace = (FindSplineAlpha - LeftSampleSplineAlpha) / RangeInSplineAlphaSpace;

					OutAlpha = RangeInSegmentAlphaSpace * PctInSplineAlphaSpace;
					return;
				}
				else
				{
					// Found the sample range for this spline position
					OutSegmentIndex = LeftSampleSegmentIndex;

					float LeftSampleSegmentAlpha = Spline.Samples_SegmentAlpha[PivotIndex];
					float RightSampleSegmentAlpha = Spline.Samples_SegmentAlpha[PivotIndex + 1];

					float RangeInSplineAlphaSpace = RightSampleSplineAlpha - LeftSampleSplineAlpha;
					if (Math::IsNearlyZero(RangeInSplineAlphaSpace))
					{
						OutAlpha = 0.0;
						return;
					}
					else
					{
						float RangeInSegmentAlphaSpace = RightSampleSegmentAlpha - LeftSampleSegmentAlpha;
						float PctInSplineAlphaSpace = (FindSplineAlpha - LeftSampleSplineAlpha) / RangeInSplineAlphaSpace;
						OutAlpha = LeftSampleSegmentAlpha + RangeInSegmentAlphaSpace * PctInSplineAlphaSpace;
						return;
					}
				}
			}
			else
			{
				// Frame is further to the right
				SearchStart = PivotIndex + 1;
			}
		}
		else
		{
			// Frame is further to the left
			SearchEnd = PivotIndex;
		}
	}

	// It shouldn't be possible to reach this ever
	check(false);
}

void FindSingleSegmentClosestToRelativeLocation(
	FHazeComputedSpline Spline, int SegmentIndex, float MinConsiderDistance, float MaxConsiderDistance, float& OutClosestDistanceSQ,
	FVector RelativeLocation, int& OutSegmentIndex, float& OutSegmentAlpha)
{
	const FHazeComputedSplineSegment& Segment = Spline.Segments[SegmentIndex];

	float DistanceToSegment = Segment.Bounds.Center.Distance(RelativeLocation) - Segment.BoundsRadius;

	// If the entire segment is more distant than our current closest point, we cannot have a closer point in it
	if (DistanceToSegment > 0.0 && Math::Square(DistanceToSegment) > OutClosestDistanceSQ)
		return;

	if (DistanceToSegment < MinConsiderDistance)
		return;
	if (DistanceToSegment > MaxConsiderDistance)
		return;

	const FHazeComputedSplinePoint& StartPoint = Spline.Points[Segment.StartPointIndex];
	const FHazeComputedSplinePoint& EndPoint = Spline.Points[Segment.EndPointIndex];

	// Perform newton's method, starting with the point that we would get if we did a linear interpolation

	int IterationCount = 0;
	float IterationScale = 0;
	for (int GuessIndex = 0; GuessIndex < 4; ++ GuessIndex)
	{
		FVector GuessPosition;
		float GuessAlpha = 0.0;
		switch (GuessIndex)
		{
			case 0:
			{
				IterationCount = 12;
				IterationScale = 0.75;

				FVector StartDelta = RelativeLocation - StartPoint.RelativeLocation;
				float DotDistance = StartDelta.DotProduct(Segment.Direction);

				if (Segment.LinearDistance > 0.0)
					GuessAlpha = Math::Clamp(DotDistance / Segment.LinearDistance, 0.0, 1.0);

				GuessPosition = Math::CubicInterp(
					StartPoint.RelativeLocation, StartPoint.LeaveTangent,
					EndPoint.RelativeLocation, EndPoint.ArriveTangent,
					GuessAlpha
				);
			}
			break;
			case 1:
				IterationCount = 3;
				IterationScale = 0.75;

				GuessAlpha = 0.0;
				GuessPosition = StartPoint.RelativeLocation;
			break;
			case 2:
				IterationCount = 3;
				IterationScale = 0.75;

				GuessAlpha = 0.5;

				GuessPosition = Math::CubicInterp(
					StartPoint.RelativeLocation, StartPoint.LeaveTangent,
					EndPoint.RelativeLocation, EndPoint.ArriveTangent,
					GuessAlpha
				);
			break;
			case 3:
				IterationCount = 3;
				IterationScale = 0.75;

				GuessAlpha = 1.0;
				GuessPosition = EndPoint.RelativeLocation;
			break;
		}

		float LastMove = 1.0;
		for (int Interation = 0; Interation < IterationCount; ++Interation)
		{
			FVector Tangent = Math::CubicInterpDerivative(
				StartPoint.RelativeLocation, StartPoint.LeaveTangent,
				EndPoint.RelativeLocation, EndPoint.ArriveTangent,
				GuessAlpha
			);

			FVector Delta = (RelativeLocation - GuessPosition);
			float TangentSize = Tangent.SizeSquared();
			if (TangentSize == 0.0)
				break;

			float MoveAlpha = Tangent.DotProduct(Delta) / TangentSize;
			MoveAlpha = Math::Clamp(MoveAlpha, -LastMove*IterationScale, LastMove*IterationScale);

			GuessAlpha += MoveAlpha;
			GuessAlpha = Math::Clamp(GuessAlpha, 0.0, 1.0);
			LastMove = Math::Abs(MoveAlpha);

			GuessPosition = Math::CubicInterp(
				StartPoint.RelativeLocation, StartPoint.LeaveTangent,
				EndPoint.RelativeLocation, EndPoint.ArriveTangent,
				GuessAlpha
			);
		}

		float DistSQ = GuessPosition.DistSquared(RelativeLocation);
		if (DistSQ < OutClosestDistanceSQ)
		{
			OutClosestDistanceSQ = DistSQ;
			OutSegmentIndex = SegmentIndex;
			OutSegmentAlpha = GuessAlpha;
		}
	}
}

void GetSegmentAlphaClosestToRelativeLocation(
	FHazeComputedSpline Spline, FVector RelativeLocation,
	int& OutSegmentIndex, float& OutSegmentAlpha,
	float& ClosestDistanceSQ)
{
	int SegmentCount = Spline.Segments.Num();

	// Heuristic: Search in spline segments that are closer than an arbitrary distance first
	float HeuristicDistance = Math::Max(Spline.BoundsRadius * 0.25, 100.0);

	for (int SegmentIndex = 0; SegmentIndex < SegmentCount; ++SegmentIndex)
		FindSingleSegmentClosestToRelativeLocation(Spline, SegmentIndex, -MAX_flt, HeuristicDistance, ClosestDistanceSQ, RelativeLocation, OutSegmentIndex, OutSegmentAlpha);

	// If we found a point closer than our heuristic distance, we've already found the closest point
	if (ClosestDistanceSQ < Math::Square(HeuristicDistance))
		return;

	// Search in all other spline segments if we can't find a match close enough
	for (int SegmentIndex = 0; SegmentIndex < SegmentCount; ++SegmentIndex)
		FindSingleSegmentClosestToRelativeLocation(Spline, SegmentIndex, HeuristicDistance, MAX_flt, ClosestDistanceSQ, RelativeLocation, OutSegmentIndex, OutSegmentAlpha);
}

struct FSplineLineSegment
{
	FVector RelativeLineStart;
	FVector RelativeLineEnd;

	FVector Delta;
	float SizeSquared;

	FSplineLineSegment(FVector InRelativeLineStart, FVector InRelativeLineEnd)
	{
		RelativeLineStart = InRelativeLineStart;
		RelativeLineEnd = InRelativeLineEnd;

		Delta = RelativeLineEnd - RelativeLineStart;
		SizeSquared = Delta.SizeSquared();
	}
};

void FindSingleSegmentClosestToRelativeLineSegment(
	FHazeComputedSpline Spline, int SegmentIndex, float MinConsiderDistance, float MaxConsiderDistance, float& OutClosestDistanceSQ,
	FSplineLineSegment LineData, int& OutSegmentIndex, float& OutSegmentAlpha)
{
	const FHazeComputedSplineSegment& Segment = Spline.Segments[SegmentIndex];

	float A = (LineData.RelativeLineStart - Segment.Bounds.Center).DotProduct(LineData.Delta);
	float T = Math::Clamp(-A/LineData.SizeSquared, 0.0, 1.0);
	FVector ClosestToSegment = LineData.RelativeLineStart + (LineData.Delta * T);

	float DistanceToSegment = Segment.Bounds.Center.Distance(ClosestToSegment) - Segment.BoundsRadius;

	// If the entire segment is more distant than our current closest point, we cannot have a closer point in it
	if (DistanceToSegment > 0.0 && Math::Square(DistanceToSegment) > OutClosestDistanceSQ)
		return;

	if (DistanceToSegment < MinConsiderDistance)
		return;
	if (DistanceToSegment > MaxConsiderDistance)
		return;

	const FHazeComputedSplinePoint& StartPoint = Spline.Points[Segment.StartPointIndex];
	const FHazeComputedSplinePoint& EndPoint = Spline.Points[Segment.EndPointIndex];

	// Perform newton's method, starting with the point that we would get if we did a linear interpolation

	int IterationCount = 0;
	float IterationScale = 0;
	for (int GuessIndex = 0; GuessIndex < 4; ++ GuessIndex)
	{
		FVector GuessPosition;
		float GuessAlpha = 0.0;
		switch (GuessIndex)
		{
			case 0:
			{
				IterationCount = 12;
				IterationScale = 0.75;

				// Even though this is a 2D intersection only, it is more likely to
				// produce an accurate initial guess than just doing closest point to bounds center.
				FVector LinearIntersection;
				bool bHasLinearIntersection = Math::SegmentIntersection2D(
					LineData.RelativeLineStart,
					LineData.RelativeLineEnd,
					StartPoint.RelativeLocation,
					EndPoint.RelativeLocation,
					LinearIntersection,
				);

				FVector StartDelta;
				if (bHasLinearIntersection)
				{
					StartDelta = LinearIntersection - StartPoint.RelativeLocation;
				}
				else
				{
					// If we can't find a linear intersection, guess based on the closest line point to
					// the segment bounds center instead
					StartDelta = ClosestToSegment - StartPoint.RelativeLocation;
				}

				float DotDistance = StartDelta.DotProduct(Segment.Direction);
				if (Segment.LinearDistance > 0.0)
					GuessAlpha = Math::Clamp(DotDistance / Segment.LinearDistance, 0.0, 1.0);

				GuessPosition = Math::CubicInterp(
					StartPoint.RelativeLocation, StartPoint.LeaveTangent,
					EndPoint.RelativeLocation, EndPoint.ArriveTangent,
					GuessAlpha
				);
			}
			break;
			case 1:
				IterationCount = 3;
				IterationScale = 0.75;

				GuessAlpha = 0.0;
				GuessPosition = StartPoint.RelativeLocation;
			break;
			case 2:
				IterationCount = 3;
				IterationScale = 0.75;

				GuessAlpha = 0.5;

				GuessPosition = Math::CubicInterp(
					StartPoint.RelativeLocation, StartPoint.LeaveTangent,
					EndPoint.RelativeLocation, EndPoint.ArriveTangent,
					GuessAlpha
				);
			break;
			case 3:
				IterationCount = 3;
				IterationScale = 0.75;

				GuessAlpha = 1.0;
				GuessPosition = EndPoint.RelativeLocation;
			break;
		}

		float LastMove = 1.0;
		FVector ClosestToGuess;
		for (int Iteration = 0; Iteration < IterationCount; ++Iteration)
		{
			FVector Tangent = Math::CubicInterpDerivative(
				StartPoint.RelativeLocation, StartPoint.LeaveTangent,
				EndPoint.RelativeLocation, EndPoint.ArriveTangent,
				GuessAlpha
			);

			A = (LineData.RelativeLineStart - GuessPosition).DotProduct(LineData.Delta);
			T = Math::Clamp(-A/LineData.SizeSquared, 0.0, 1.0);

			ClosestToGuess = LineData.RelativeLineStart + (LineData.Delta * T);
			FVector Delta = (ClosestToGuess - GuessPosition);

			float TangentSize = Tangent.SizeSquared();
			if (TangentSize < SMALL_NUMBER)
				break;

			float MoveAlpha = Tangent.DotProduct(Delta) / TangentSize;
			MoveAlpha = Math::Clamp(MoveAlpha, -LastMove*IterationScale, LastMove*IterationScale);
			if (MoveAlpha == 0.0)
				break;

			GuessAlpha += MoveAlpha;
			GuessAlpha = Math::Clamp(GuessAlpha, 0.0, 1.0);
			LastMove = Math::Abs(MoveAlpha);

			GuessPosition = Math::CubicInterp(
				StartPoint.RelativeLocation, StartPoint.LeaveTangent,
				EndPoint.RelativeLocation, EndPoint.ArriveTangent,
				GuessAlpha
			);
		}

		float DistSQ = GuessPosition.DistSquared(ClosestToGuess);
		if (DistSQ < OutClosestDistanceSQ)
		{
			OutClosestDistanceSQ = DistSQ;
			OutSegmentIndex = SegmentIndex;
			OutSegmentAlpha = GuessAlpha;
		}
	}
}

void GetSegmentAlphaClosestToRelativeLineSegment(
	FHazeComputedSpline Spline, FVector RelativeLineStart, FVector RelativeLineEnd,
	int& OutSegmentIndex, float& OutSegmentAlpha,
	float& ClosestDistanceSQ)
{
	int SegmentCount = Spline.Segments.Num();

	FSplineLineSegment LineSegment(RelativeLineStart, RelativeLineEnd);
	if (LineSegment.SizeSquared == 0.0)
	{
		// If this is a zero-size line, fall back to getting the closest to point
		GetSegmentAlphaClosestToRelativeLocation(Spline, RelativeLineStart, OutSegmentIndex, OutSegmentAlpha, ClosestDistanceSQ);
		return;
	}

	// Heuristic: Search in spline segments that are closer than an arbitrary distance first
	float HeuristicDistance = Math::Max(Spline.BoundsRadius * 0.25, 100.0);

	for (int SegmentIndex = 0; SegmentIndex < SegmentCount; ++SegmentIndex)
	{
		FindSingleSegmentClosestToRelativeLineSegment(Spline, SegmentIndex, -MAX_flt,
			HeuristicDistance, ClosestDistanceSQ,
			LineSegment, OutSegmentIndex, OutSegmentAlpha);
	}

	// If we found a point closer than our heuristic distance, we've already found the closest point
	if (ClosestDistanceSQ < Math::Square(HeuristicDistance))
		return;

	// Search in all other spline segments if we can't find a match close enough
	for (int SegmentIndex = 0; SegmentIndex < SegmentCount; ++SegmentIndex)
	{
		FindSingleSegmentClosestToRelativeLineSegment(Spline, SegmentIndex, HeuristicDistance,
			MAX_flt, ClosestDistanceSQ,
			LineSegment, OutSegmentIndex, OutSegmentAlpha);
	}
}

void FindSingleSegmentPlaneConstrainedClosestToRelativeLineSegment(
	FHazeComputedSpline Spline, int SegmentIndex, float MinConsiderDistance, float MaxConsiderDistance, float& OutClosestDistanceSQ,
	FSplineLineSegment LineData, int& OutSegmentIndex, float& OutSegmentAlpha, FVector ConstrainPlaneNormal)
{
	const FHazeComputedSplineSegment& Segment = Spline.Segments[SegmentIndex];

	FVector ConstrainedBoundsCenter = Segment.Bounds.Center.ConstrainToPlane(ConstrainPlaneNormal);

	float A = (LineData.RelativeLineStart - ConstrainedBoundsCenter).DotProduct(LineData.Delta);
	float T = Math::Clamp(-A/LineData.SizeSquared, 0.0, 1.0);
	FVector ClosestToSegment = LineData.RelativeLineStart + (LineData.Delta * T);

	float DistanceToSegment = ConstrainedBoundsCenter.Distance(ClosestToSegment) - Segment.BoundsRadius;

	// If the entire segment is more distant than our current closest point, we cannot have a closer point in it
	if (DistanceToSegment > 0.0 && Math::Square(DistanceToSegment) > OutClosestDistanceSQ)
		return;

	if (DistanceToSegment < MinConsiderDistance)
		return;
	if (DistanceToSegment > MaxConsiderDistance)
		return;

	const FHazeComputedSplinePoint& StartPoint = Spline.Points[Segment.StartPointIndex];
	const FHazeComputedSplinePoint& EndPoint = Spline.Points[Segment.EndPointIndex];

	// Perform newton's method, starting with the point that we would get if we did a linear interpolation

	int IterationCount = 0;
	float IterationScale = 0;
	for (int GuessIndex = 0; GuessIndex < 4; ++ GuessIndex)
	{
		FVector GuessPosition;
		float GuessAlpha = 0.0;
		switch (GuessIndex)
		{
			case 0:
			{
				IterationCount = 12;
				IterationScale = 0.75;

				// Even though this is a 2D intersection only, it is more likely to
				// produce an accurate initial guess than just doing closest point to bounds center.
				FVector LinearIntersection;
				bool bHasLinearIntersection = Math::SegmentIntersection2D(
					LineData.RelativeLineStart,
					LineData.RelativeLineEnd,
					StartPoint.RelativeLocation,
					EndPoint.RelativeLocation,
					LinearIntersection,
				);

				FVector StartDelta;
				if (bHasLinearIntersection)
				{
					StartDelta = LinearIntersection - StartPoint.RelativeLocation;
				}
				else
				{
					// If we can't find a linear intersection, guess based on the closest line point to
					// the segment bounds center instead
					StartDelta = ClosestToSegment - StartPoint.RelativeLocation;
				}

				StartDelta = StartDelta.ConstrainToPlane(ConstrainPlaneNormal);
				float DotDistance = StartDelta.DotProduct(Segment.Direction.ConstrainToPlane(ConstrainPlaneNormal).GetSafeNormal());

				FVector SegmentDelta = (EndPoint.RelativeLocation - StartPoint.RelativeLocation);
				float SegmentLinearSize = SegmentDelta.ConstrainToPlane(ConstrainPlaneNormal).Size();

				if (Segment.LinearDistance > 0.0)
					GuessAlpha = Math::Clamp(DotDistance / SegmentLinearSize, 0.0, 1.0);

				GuessPosition = Math::CubicInterp(
					StartPoint.RelativeLocation, StartPoint.LeaveTangent,
					EndPoint.RelativeLocation, EndPoint.ArriveTangent,
					GuessAlpha
				).ConstrainToPlane(ConstrainPlaneNormal);
			}
			break;
			case 1:
				IterationCount = 3;
				IterationScale = 0.75;

				GuessAlpha = 0.0;
				GuessPosition = StartPoint.RelativeLocation.ConstrainToPlane(ConstrainPlaneNormal);
			break;
			case 2:
				IterationCount = 3;
				IterationScale = 0.75;

				GuessAlpha = 0.5;

				GuessPosition = Math::CubicInterp(
					StartPoint.RelativeLocation, StartPoint.LeaveTangent,
					EndPoint.RelativeLocation, EndPoint.ArriveTangent,
					GuessAlpha
				).ConstrainToPlane(ConstrainPlaneNormal);
			break;
			case 3:
				IterationCount = 3;
				IterationScale = 0.75;

				GuessAlpha = 1.0;
				GuessPosition = EndPoint.RelativeLocation.ConstrainToPlane(ConstrainPlaneNormal);
			break;
		}

		float LastMove = 1.0;
		FVector ClosestToGuess;
		for (int Iteration = 0; Iteration < IterationCount; ++Iteration)
		{
			FVector Tangent = Math::CubicInterpDerivative(
				StartPoint.RelativeLocation, StartPoint.LeaveTangent,
				EndPoint.RelativeLocation, EndPoint.ArriveTangent,
				GuessAlpha
			).ConstrainToPlane(ConstrainPlaneNormal);

			A = (LineData.RelativeLineStart - GuessPosition).DotProduct(LineData.Delta);
			T = Math::Clamp(-A/LineData.SizeSquared, 0.0, 1.0);

			ClosestToGuess = LineData.RelativeLineStart + (LineData.Delta * T);
			FVector Delta = (ClosestToGuess - GuessPosition);

			float TangentSize = Tangent.SizeSquared();
			if (TangentSize < SMALL_NUMBER)
				break;

			float MoveAlpha = Tangent.DotProduct(Delta) / TangentSize;
			MoveAlpha = Math::Clamp(MoveAlpha, -LastMove*IterationScale, LastMove*IterationScale);
			if (MoveAlpha == 0.0)
				break;

			GuessAlpha += MoveAlpha;
			GuessAlpha = Math::Clamp(GuessAlpha, 0.0, 1.0);
			LastMove = Math::Abs(MoveAlpha);

			GuessPosition = Math::CubicInterp(
				StartPoint.RelativeLocation, StartPoint.LeaveTangent,
				EndPoint.RelativeLocation, EndPoint.ArriveTangent,
				GuessAlpha
			).ConstrainToPlane(ConstrainPlaneNormal);
		}

		float DistSQ = GuessPosition.DistSquared(ClosestToGuess);
		if (DistSQ < OutClosestDistanceSQ)
		{
			OutClosestDistanceSQ = DistSQ;
			OutSegmentIndex = SegmentIndex;
			OutSegmentAlpha = GuessAlpha;
		}
	}
}

void GetSegmentAlphaPlaneConstrainedClosestToRelativeLineSegment(
	FHazeComputedSpline Spline, FVector RelativeLineStart, FVector RelativeLineEnd,
	int& OutSegmentIndex, float& OutSegmentAlpha,
	FVector ConstrainPlaneNormal, float& ClosestDistanceSQ)
{
	int SegmentCount = Spline.Segments.Num();

	FSplineLineSegment LineSegment(
		RelativeLineStart.ConstrainToPlane(ConstrainPlaneNormal),
		RelativeLineEnd.ConstrainToPlane(ConstrainPlaneNormal));

	if (LineSegment.SizeSquared == 0.0)
	{
		// If this is a zero-size line, fall back to getting the closest to point
		GetSegmentAlphaPlaneClosestToRelativeLocation(Spline, RelativeLineStart, OutSegmentIndex, OutSegmentAlpha, ConstrainPlaneNormal, ClosestDistanceSQ);
		return;
	}

	// Heuristic: Search in spline segments that are closer than an arbitrary distance first
	float HeuristicDistance = Math::Max(Spline.BoundsRadius * 0.25, 100.0);

	for (int SegmentIndex = 0; SegmentIndex < SegmentCount; ++SegmentIndex)
	{
		FindSingleSegmentPlaneConstrainedClosestToRelativeLineSegment(Spline, SegmentIndex, -MAX_flt,
			HeuristicDistance, ClosestDistanceSQ,
			LineSegment, OutSegmentIndex, OutSegmentAlpha, ConstrainPlaneNormal);
	}

	// If we found a point closer than our heuristic distance, we've already found the closest point
	if (ClosestDistanceSQ < Math::Square(HeuristicDistance))
		return;

	// Search in all other spline segments if we can't find a match close enough
	for (int SegmentIndex = 0; SegmentIndex < SegmentCount; ++SegmentIndex)
	{
		FindSingleSegmentPlaneConstrainedClosestToRelativeLineSegment(Spline, SegmentIndex, HeuristicDistance,
			MAX_flt, ClosestDistanceSQ,
			LineSegment, OutSegmentIndex, OutSegmentAlpha, ConstrainPlaneNormal);
	}
}

void FindSingleSegmentConstrainedClosestToRelativeLocation(
	FHazeComputedSpline Spline, int SegmentIndex, float MinConsiderDistance,
	float MaxConsiderDistance, float& OutClosestDistanceSQ,
	FVector RelativeLocation, int& OutSegmentIndex, float& OutSegmentAlpha,
	FVector ConstrainAxis)
{
	const FHazeComputedSplineSegment& Segment = Spline.Segments[SegmentIndex];

	FVector ConstrainedBoundsCenter = Segment.Bounds.Center.ConstrainToDirection(ConstrainAxis);
	float DistanceToSegment = ConstrainedBoundsCenter.Distance(RelativeLocation) - Segment.BoundsRadius;

	// If the entire segment is more distant than our current closest point, we cannot have a closer point in it
	if (DistanceToSegment > 0.0 && Math::Square(DistanceToSegment) > OutClosestDistanceSQ)
		return;

	if (DistanceToSegment < MinConsiderDistance)
		return;
	if (DistanceToSegment > MaxConsiderDistance)
		return;

	const FHazeComputedSplinePoint& StartPoint = Spline.Points[Segment.StartPointIndex];
	const FHazeComputedSplinePoint& EndPoint = Spline.Points[Segment.EndPointIndex];

	// Perform newton's method, starting with the point that we would get if we did a linear interpolation
	int IterationCount = 3;
	float IterationScale = 0.75;
	for (int GuessIndex = 1; GuessIndex < 4; ++ GuessIndex)
	{
		float GuessAlpha = 0.0;
		FVector GuessPosition;

		switch (GuessIndex)
		{
			case 0:
			{
				IterationCount = 12;
				IterationScale = 0.75;

				FVector StartDelta = RelativeLocation - StartPoint.RelativeLocation;
				StartDelta = StartDelta.ConstrainToDirection(ConstrainAxis);
				float DotDistance = StartDelta.DotProduct(Segment.Direction.ConstrainToDirection(ConstrainAxis).GetSafeNormal());

				FVector SegmentDelta = (EndPoint.RelativeLocation - StartPoint.RelativeLocation);
				float SegmentLinearSize = SegmentDelta.ConstrainToDirection(ConstrainAxis).Size();

				if (Segment.LinearDistance > 0.0)
					GuessAlpha = Math::Clamp(DotDistance / SegmentLinearSize, 0.0, 1.0);

				GuessPosition = Math::CubicInterp(
					StartPoint.RelativeLocation, StartPoint.LeaveTangent,
					EndPoint.RelativeLocation, EndPoint.ArriveTangent,
					GuessAlpha
				);
			}
			break;
			case 1:
				IterationCount = 3;
				IterationScale = 0.75;

				GuessAlpha = 0.0;
				GuessPosition = StartPoint.RelativeLocation;
			break;
			case 2:
				IterationCount = 3;
				IterationScale = 0.75;

				GuessAlpha = 0.5;

				GuessPosition = Math::CubicInterp(
					StartPoint.RelativeLocation, StartPoint.LeaveTangent,
					EndPoint.RelativeLocation, EndPoint.ArriveTangent,
					GuessAlpha
				);
			break;
			case 3:
				IterationCount = 3;
				IterationScale = 0.75;

				GuessAlpha = 1.0;
				GuessPosition = EndPoint.RelativeLocation;
			break;
		}

		float LastMove = 1.0;
		for (int Interation = 0; Interation < IterationCount; ++Interation)
		{
			FVector Tangent = Math::CubicInterpDerivative(
				StartPoint.RelativeLocation, StartPoint.LeaveTangent,
				EndPoint.RelativeLocation, EndPoint.ArriveTangent,
				GuessAlpha
			).ConstrainToDirection(ConstrainAxis);

			if (Tangent.IsNearlyZero())
				break;

			FVector Delta = (RelativeLocation - GuessPosition).ConstrainToDirection(ConstrainAxis);
			float MoveAlpha = Tangent.DotProduct(Delta) / Tangent.SizeSquared();
			MoveAlpha = Math::Clamp(MoveAlpha, -LastMove*IterationScale, LastMove*IterationScale);

			GuessAlpha += MoveAlpha;
			GuessAlpha = Math::Clamp(GuessAlpha, 0.0, 1.0);
			LastMove = Math::Abs(MoveAlpha);

			GuessPosition = Math::CubicInterp(
				StartPoint.RelativeLocation, StartPoint.LeaveTangent,
				EndPoint.RelativeLocation, EndPoint.ArriveTangent,
				GuessAlpha
			);
		}

		FVector ConstrainedGuessPosition = GuessPosition.ConstrainToDirection(ConstrainAxis);
		float DistSQ = ConstrainedGuessPosition.DistSquared(RelativeLocation);
		if (DistSQ < OutClosestDistanceSQ)
		{
			OutClosestDistanceSQ = DistSQ;
			OutSegmentIndex = SegmentIndex;
			OutSegmentAlpha = GuessAlpha;
		}
	}
}

void GetSegmentAlphaConstrainedClosestToRelativeLocation(
	FHazeComputedSpline Spline, FVector RelativeLocation,
	int& OutSegmentIndex, float& OutSegmentAlpha,
	FVector ConstrainAxis, float& ClosestDistanceSQ)
{
	int SegmentCount = Spline.Segments.Num();
	FVector ConstrainedRelativeLocation = RelativeLocation.ConstrainToDirection(ConstrainAxis);

	// Heuristic: Search in spline segments that are closer than an arbitrary distance first
	float HeuristicDistance = Math::Max(Spline.BoundsRadius * 0.25, 100.0);

	for (int SegmentIndex = 0; SegmentIndex < SegmentCount; ++SegmentIndex)
		FindSingleSegmentConstrainedClosestToRelativeLocation(Spline, SegmentIndex, -MAX_flt, HeuristicDistance, ClosestDistanceSQ, ConstrainedRelativeLocation, OutSegmentIndex, OutSegmentAlpha, ConstrainAxis);

	// If we found a point closer than our heuristic distance, we've already found the closest point
	if (ClosestDistanceSQ < Math::Square(HeuristicDistance))
		return;

	// Search in all other spline segments if we can't find a match close enough
	for (int SegmentIndex = 0; SegmentIndex < SegmentCount; ++SegmentIndex)
		FindSingleSegmentConstrainedClosestToRelativeLocation(Spline, SegmentIndex, HeuristicDistance, MAX_flt, ClosestDistanceSQ, ConstrainedRelativeLocation, OutSegmentIndex, OutSegmentAlpha, ConstrainAxis);
}

void FindSingleSegmentPlaneClosestToRelativeLocation(
	FHazeComputedSpline Spline, int SegmentIndex, float MinConsiderDistance,
	float MaxConsiderDistance, float& OutClosestDistanceSQ,
	FVector RelativeLocation, int& OutSegmentIndex, float& OutSegmentAlpha,
	FVector ConstrainPlaneNormal)
{
	const FHazeComputedSplineSegment& Segment = Spline.Segments[SegmentIndex];

	FVector ConstrainedBoundsCenter = Segment.Bounds.Center.ConstrainToPlane(ConstrainPlaneNormal);
	float DistanceToSegment = ConstrainedBoundsCenter.Distance(RelativeLocation) - Segment.BoundsRadius;

	// If the entire segment is more distant than our current closest point, we cannot have a closer point in it
	if (DistanceToSegment > 0.0 && Math::Square(DistanceToSegment) > OutClosestDistanceSQ)
		return;

	if (DistanceToSegment < MinConsiderDistance)
		return;
	if (DistanceToSegment > MaxConsiderDistance)
		return;

	const FHazeComputedSplinePoint& StartPoint = Spline.Points[Segment.StartPointIndex];
	const FHazeComputedSplinePoint& EndPoint = Spline.Points[Segment.EndPointIndex];

	// Perform newton's method, starting with the point that we would get if we did a linear interpolation
	int IterationCount = 3;
	float IterationScale = 0.75;
	for (int GuessIndex = 1; GuessIndex < 4; ++ GuessIndex)
	{
		float GuessAlpha = 0.0;
		FVector GuessPosition;

		switch (GuessIndex)
		{
			case 0:
			{
				IterationCount = 12;
				IterationScale = 0.75;

				FVector StartDelta = RelativeLocation - StartPoint.RelativeLocation;
				StartDelta = StartDelta.ConstrainToPlane(ConstrainPlaneNormal);
				float DotDistance = StartDelta.DotProduct(Segment.Direction.ConstrainToPlane(ConstrainPlaneNormal).GetSafeNormal());

				FVector SegmentDelta = (EndPoint.RelativeLocation - StartPoint.RelativeLocation);
				float SegmentLinearSize = SegmentDelta.ConstrainToPlane(ConstrainPlaneNormal).Size();

				if (Segment.LinearDistance > 0.0)
					GuessAlpha = Math::Clamp(DotDistance / SegmentLinearSize, 0.0, 1.0);

				GuessPosition = Math::CubicInterp(
					StartPoint.RelativeLocation, StartPoint.LeaveTangent,
					EndPoint.RelativeLocation, EndPoint.ArriveTangent,
					GuessAlpha
				);
			}
			break;
			case 1:
				IterationCount = 3;
				IterationScale = 0.75;

				GuessAlpha = 0.0;
				GuessPosition = StartPoint.RelativeLocation;
			break;
			case 2:
				IterationCount = 3;
				IterationScale = 0.75;

				GuessAlpha = 0.5;

				GuessPosition = Math::CubicInterp(
					StartPoint.RelativeLocation, StartPoint.LeaveTangent,
					EndPoint.RelativeLocation, EndPoint.ArriveTangent,
					GuessAlpha
				);
			break;
			case 3:
				IterationCount = 3;
				IterationScale = 0.75;

				GuessAlpha = 1.0;
				GuessPosition = EndPoint.RelativeLocation;
			break;
		}

		float LastMove = 1.0;
		for (int Interation = 0; Interation < IterationCount; ++Interation)
		{
			FVector Tangent = Math::CubicInterpDerivative(
				StartPoint.RelativeLocation, StartPoint.LeaveTangent,
				EndPoint.RelativeLocation, EndPoint.ArriveTangent,
				GuessAlpha
			).ConstrainToPlane(ConstrainPlaneNormal);

			if (Tangent.IsNearlyZero())
				break;

			FVector Delta = (RelativeLocation - GuessPosition).ConstrainToPlane(ConstrainPlaneNormal);
			float MoveAlpha = Tangent.DotProduct(Delta) / Tangent.SizeSquared();
			MoveAlpha = Math::Clamp(MoveAlpha, -LastMove*IterationScale, LastMove*IterationScale);

			GuessAlpha += MoveAlpha;
			GuessAlpha = Math::Clamp(GuessAlpha, 0.0, 1.0);
			LastMove = Math::Abs(MoveAlpha);

			GuessPosition = Math::CubicInterp(
				StartPoint.RelativeLocation, StartPoint.LeaveTangent,
				EndPoint.RelativeLocation, EndPoint.ArriveTangent,
				GuessAlpha
			);
		}

		FVector ConstrainedGuessPosition = GuessPosition.ConstrainToPlane(ConstrainPlaneNormal);
		float DistSQ = ConstrainedGuessPosition.DistSquared(RelativeLocation);
		if (DistSQ < OutClosestDistanceSQ)
		{
			OutClosestDistanceSQ = DistSQ;
			OutSegmentIndex = SegmentIndex;
			OutSegmentAlpha = GuessAlpha;
		}
	}
}

void GetSegmentAlphaPlaneClosestToRelativeLocation(
	FHazeComputedSpline Spline, FVector RelativeLocation,
	int& OutSegmentIndex, float& OutSegmentAlpha,
	FVector ConstrainPlaneNormal, float& ClosestDistanceSQ)
{
	int SegmentCount = Spline.Segments.Num();

	FVector ConstrainedRelativeLocation = RelativeLocation.ConstrainToPlane(ConstrainPlaneNormal);

	// Heuristic: Search in spline segments that are closer than an arbitrary distance first
	float HeuristicDistance = Math::Max(Spline.BoundsRadius * 0.25, 100.0);

	for (int SegmentIndex = 0; SegmentIndex < SegmentCount; ++SegmentIndex)
		FindSingleSegmentPlaneClosestToRelativeLocation(Spline, SegmentIndex, -MAX_flt, HeuristicDistance, ClosestDistanceSQ, ConstrainedRelativeLocation, OutSegmentIndex, OutSegmentAlpha, ConstrainPlaneNormal);

	// If we found a point closer than our heuristic distance, we've already found the closest point
	if (ClosestDistanceSQ < Math::Square(HeuristicDistance))
		return;

	// Search in all other spline segments if we can't find a match close enough
	for (int SegmentIndex = 0; SegmentIndex < SegmentCount; ++SegmentIndex)
		FindSingleSegmentPlaneClosestToRelativeLocation(Spline, SegmentIndex, HeuristicDistance, MAX_flt, ClosestDistanceSQ, ConstrainedRelativeLocation, OutSegmentIndex, OutSegmentAlpha, ConstrainPlaneNormal);
}

float GetSplineDistanceAtSegmentAlpha(FHazeComputedSpline Spline, int SegmentIndex, float SegmentAlpha)
{
	if (!Spline.Segments.IsValidIndex(SegmentIndex))
		return 0.0;

	const FHazeComputedSplineSegment& Segment = Spline.Segments[SegmentIndex];

	if (SegmentAlpha <= SMALL_NUMBER)
	{
		const FHazeComputedSplinePoint& StartPoint = Spline.Points[Segment.StartPointIndex];
		return StartPoint.SplineDistance;
	}
	else if (SegmentAlpha >= 1.0 - SMALL_NUMBER)
	{
		const FHazeComputedSplinePoint& EndPoint = Spline.Points[Segment.EndPointIndex];
		return EndPoint.SplineDistance;
	}

	// NOTE: This relies on all spline samples within a segment being equally spaced in alpha
	float AlphaInterval = 1.0 / float(Segment.SampleCount - 1);

	int LeftIndex = Math::FloorToInt(SegmentAlpha / AlphaInterval);
	float LeftAlpha = float(LeftIndex) * AlphaInterval;
	int LeftSampleIndex = Segment.StartSampleIndex + Math::Clamp(LeftIndex, 0, Segment.SampleCount - 1);
	int RightSampleIndex = Math::Clamp(LeftSampleIndex+1, 0, Spline.Samples_SplineAlpha.Num()-1);

	float LeftSampleSplineDistance = Spline.Samples_SplineAlpha[LeftSampleIndex] * Spline.SplineLength;
	if (LeftSampleIndex == RightSampleIndex)
		return LeftSampleSplineDistance;

	float RightSampleSplineDistance = Spline.Samples_SplineAlpha[RightSampleIndex] * Spline.SplineLength;
	float AlphaWithinSample = (SegmentAlpha - LeftAlpha) / AlphaInterval;
	return LeftSampleSplineDistance + (AlphaWithinSample * (RightSampleSplineDistance - LeftSampleSplineDistance));
}

FVector GetRelativeLocationAtSplineDistance(FHazeComputedSpline Spline, float SplineDistance)
{
	int SegmentIndex = 0;
	float SegmentAlpha = 0.0;

	GetSegmentAlphaAtSplineDistance(Spline, SplineDistance, SegmentIndex, SegmentAlpha);
	return GetRelativeLocationAtSegmentAlpha(Spline, SegmentIndex, SegmentAlpha);
}

FQuat GetRelativeRotationAtSplineDistance(FHazeComputedSpline Spline, float SplineDistance)
{
	int SegmentIndex = 0;
	float SegmentAlpha = 0.0;

	GetSegmentAlphaAtSplineDistance(Spline, SplineDistance, SegmentIndex, SegmentAlpha);
	return GetRelativeRotationAtSegmentAlpha(Spline, SegmentIndex, SegmentAlpha);
}

FVector GetRelativeScale3DAtSplineDistance(FHazeComputedSpline Spline, float SplineDistance)
{
	int SegmentIndex = 0;
	float SegmentAlpha = 0.0;

	GetSegmentAlphaAtSplineDistance(Spline, SplineDistance, SegmentIndex, SegmentAlpha);
	return GetRelativeScale3DAtSegmentAlpha(Spline, SegmentIndex, SegmentAlpha);
}

FVector GetRelativeTangentAtSplineDistance(FHazeComputedSpline Spline, float SplineDistance)
{
	int SegmentIndex = 0;
	float SegmentAlpha = 0.0;

	GetSegmentAlphaAtSplineDistance(Spline, SplineDistance, SegmentIndex, SegmentAlpha);
	return GetRelativeTangentAtSegmentAlpha(Spline, SegmentIndex, SegmentAlpha);
}

FVector GetRelativeForwardVectorAtSplineDistance(FHazeComputedSpline Spline, float SplineDistance)
{
	int SegmentIndex = 0;
	float SegmentAlpha = 0.0;

	GetSegmentAlphaAtSplineDistance(Spline, SplineDistance, SegmentIndex, SegmentAlpha);
	return GetRelativeTangentAtSegmentAlpha(Spline, SegmentIndex, SegmentAlpha).GetSafeNormal();
}

FTransform GetRelativeTransformAtSplineDistance(FHazeComputedSpline Spline, float SplineDistance)
{
	int SegmentIndex = 0;
	float SegmentAlpha = 0.0;

	GetSegmentAlphaAtSplineDistance(Spline, SplineDistance, SegmentIndex, SegmentAlpha);
	return GetRelativeTransformAtSegmentAlpha(Spline, SegmentIndex, SegmentAlpha);
}

float GetClosestSplineDistanceToRelativeLocation(FHazeComputedSpline Spline, FVector RelativeLocation)
{
	int SegmentIndex = 0;
	float SegmentAlpha = 0.0;

	float ClosestDistanceSQ = MAX_flt;
	GetSegmentAlphaClosestToRelativeLocation(Spline, RelativeLocation, SegmentIndex, SegmentAlpha, ClosestDistanceSQ);

	return GetSplineDistanceAtSegmentAlpha(Spline, SegmentIndex, SegmentAlpha);
}

FTransform GetClosestTransformToRelativeLocation(FHazeComputedSpline Spline, FVector RelativeLocation)
{
	int SegmentIndex = 0;
	float SegmentAlpha = 0.0;

	float ClosestDistanceSQ = MAX_flt;
	GetSegmentAlphaClosestToRelativeLocation(Spline, RelativeLocation, SegmentIndex, SegmentAlpha, ClosestDistanceSQ);
	return GetRelativeTransformAtSegmentAlpha(Spline, SegmentIndex, SegmentAlpha);
}

FVector GetClosestRelativeLocationToRelativeLocation(FHazeComputedSpline Spline, FVector RelativeLocation)
{
	int SegmentIndex = 0;
	float SegmentAlpha = 0.0;

	float ClosestDistanceSQ = MAX_flt;
	GetSegmentAlphaClosestToRelativeLocation(Spline, RelativeLocation, SegmentIndex, SegmentAlpha, ClosestDistanceSQ);
	return GetRelativeLocationAtSegmentAlpha(Spline, SegmentIndex, SegmentAlpha);
}

FQuat GetClosestRelativeRotationToRelativeLocation(FHazeComputedSpline Spline, FVector RelativeLocation)
{
	int SegmentIndex = 0;
	float SegmentAlpha = 0.0;

	float ClosestDistanceSQ = MAX_flt;
	GetSegmentAlphaClosestToRelativeLocation(Spline, RelativeLocation, SegmentIndex, SegmentAlpha, ClosestDistanceSQ);
	return GetRelativeRotationAtSegmentAlpha(Spline, SegmentIndex, SegmentAlpha);
}

}
