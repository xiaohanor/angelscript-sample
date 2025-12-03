/**
 * Get the spline position closes to the specified world location.
 * 
 * If bSearchConnections is true, this could also be a position on a different, connected spline.
 */
mixin FSplinePosition GetClosestSplinePositionToWorldLocation(UHazeSplineComponent Spline, FVector WorldLocation, bool bSearchConnections = true)
{
	if (bSearchConnections && Spline.SplineConnections.Num() != 0)
	{
		TArray<UHazeSplineComponent> AllSplines = Spline.GetAllLinkedSplines();

		UHazeSplineComponent BestComponent = nullptr;

		float BestPointDistanceSQ = MAX_flt;
		int BestSegmentIndex = 0;
		float BestSegmentAlpha = 0.0;

		for (UHazeSplineComponent CheckSpline : AllSplines)
		{
			// If the spline we're checking is completely further away than our current closest point,
			// we can ignore it - no point on it will be close enough.
			FVector SplineCenter = CheckSpline.WorldTransform.TransformPosition(CheckSpline.ComputedSpline.Bounds.Center);
			float DistanceToBounds = SplineCenter.Distance(WorldLocation) - CheckSpline.ComputedSpline.BoundsRadius;
			if (DistanceToBounds > 0.0 && Math::Square(DistanceToBounds) > BestPointDistanceSQ)
				continue;

			// Find the closest point on this spline and compare it to our current closest
			FTransform CheckSplineTransform = CheckSpline.WorldTransform;

			int SegmentIndex = -1;
			float SegmentAlpha = 0.0;
			SplineComputation::GetSegmentAlphaClosestToRelativeLocation(
				CheckSpline.ComputedSpline,
				CheckSplineTransform.InverseTransformPosition(WorldLocation),
				SegmentIndex,
				SegmentAlpha,
				BestPointDistanceSQ
			);

			if (SegmentIndex != -1)
			{
				BestSegmentIndex = SegmentIndex;
				BestSegmentAlpha = SegmentAlpha;
				BestComponent = CheckSpline;
			}
		}

		if (BestComponent != nullptr)
		{
			return FSplinePosition(
				BestComponent, 
				SplineComputation::GetSplineDistanceAtSegmentAlpha(
					BestComponent.ComputedSpline, BestSegmentIndex, BestSegmentAlpha),
				true);
		}
		else
		{
			return FSplinePosition();
		}
	}

	return FSplinePosition(
		Spline,
		Spline.GetClosestSplineDistanceToWorldLocation(WorldLocation),
		bForwardFacing = true,
	);
}

/**
 * Get the spline position that is closest to the specified world location on the specified axis.
 * 
 * If bSearchConnections is true, this could also be a position on a different, connected spline.
 */
mixin FSplinePosition GetAxisConstrainedClosestSplinePositionToWorldLocation(UHazeSplineComponent Spline, FVector WorldLocation, FVector ConstrainWorldAxis, bool bSearchConnections = true)
{
	UHazeSplineComponent BestComponent = nullptr;
	float BestPointDistanceSQ = MAX_flt;
	int BestSegmentIndex = 0;
	float BestSegmentAlpha = 0.0;

	if (bSearchConnections && Spline.SplineConnections.Num() != 0)
	{
		TArray<UHazeSplineComponent> AllSplines = Spline.GetAllLinkedSplines();
		FVector ConstrainedWorldLocation = WorldLocation.ConstrainToDirection(ConstrainWorldAxis);

		for (UHazeSplineComponent CheckSpline : AllSplines)
		{
			// If the spline we're checking is completely further away than our current closest point,
			// we can ignore it - no point on it will be close enough.
			FVector SplineCenter = CheckSpline.WorldTransform.TransformPosition(CheckSpline.ComputedSpline.Bounds.Center);
			SplineCenter = SplineCenter.ConstrainToDirection(ConstrainWorldAxis);

			float DistanceToBounds = SplineCenter.Distance(ConstrainedWorldLocation) - CheckSpline.ComputedSpline.BoundsRadius;
			if (DistanceToBounds > 0.0 && Math::Square(DistanceToBounds) > BestPointDistanceSQ)
				continue;

			// Find the closest point on this spline and compare it to our current closest
			FTransform CheckSplineTransform = CheckSpline.WorldTransform;

			int SegmentIndex = -1;
			float SegmentAlpha = 0.0;
			SplineComputation::GetSegmentAlphaConstrainedClosestToRelativeLocation(
				CheckSpline.ComputedSpline,
				CheckSplineTransform.InverseTransformPosition(WorldLocation),
				SegmentIndex,
				SegmentAlpha,
				CheckSplineTransform.InverseTransformVectorNoScale(ConstrainWorldAxis).GetSafeNormal(),
				BestPointDistanceSQ
			);

			if (SegmentIndex != -1)
			{
				BestSegmentIndex = SegmentIndex;
				BestSegmentAlpha = SegmentAlpha;
				BestComponent = CheckSpline;
			}
		}

	}
	else
	{
		BestComponent = Spline;

		FTransform CheckSplineTransform = Spline.WorldTransform;
		SplineComputation::GetSegmentAlphaConstrainedClosestToRelativeLocation(
			Spline.ComputedSpline,
			CheckSplineTransform.InverseTransformPosition(WorldLocation),
			BestSegmentIndex,
			BestSegmentAlpha,
			CheckSplineTransform.InverseTransformVectorNoScale(ConstrainWorldAxis).GetSafeNormal(),
			BestPointDistanceSQ
		);
	}

	if (BestComponent != nullptr)
	{
		return FSplinePosition(
			BestComponent, 
			SplineComputation::GetSplineDistanceAtSegmentAlpha(
				BestComponent.ComputedSpline, BestSegmentIndex, BestSegmentAlpha),
			true);
	}
	else
	{
		return FSplinePosition();
	}
}

/**
 * Get the spline position that is closest to the specified world location on the specified plane.
 * 
 * If bSearchConnections is true, this could also be a position on a different, connected spline.
 */
mixin FSplinePosition GetPlaneConstrainedClosestSplinePositionToWorldLocation(UHazeSplineComponent Spline, FVector WorldLocation, FVector ConstrainWorldPlaneNormal, bool bSearchConnections = true)
{
	UHazeSplineComponent BestComponent = nullptr;
	float BestPointDistanceSQ = MAX_flt;
	int BestSegmentIndex = 0;
	float BestSegmentAlpha = 0.0;

	if (bSearchConnections && Spline.SplineConnections.Num() != 0)
	{
		TArray<UHazeSplineComponent> AllSplines = Spline.GetAllLinkedSplines();
		FVector ConstrainedWorldLocation = WorldLocation.ConstrainToPlane(ConstrainWorldPlaneNormal);

		for (UHazeSplineComponent CheckSpline : AllSplines)
		{
			// If the spline we're checking is completely further away than our current closest point,
			// we can ignore it - no point on it will be close enough.
			FVector SplineCenter = CheckSpline.WorldTransform.TransformPosition(CheckSpline.ComputedSpline.Bounds.Center);
			SplineCenter = SplineCenter.ConstrainToPlane(ConstrainWorldPlaneNormal);

			float DistanceToBounds = SplineCenter.Distance(ConstrainedWorldLocation) - CheckSpline.ComputedSpline.BoundsRadius;
			if (DistanceToBounds > 0.0 && Math::Square(DistanceToBounds) > BestPointDistanceSQ)
				continue;

			// Find the closest point on this spline and compare it to our current closest
			FTransform CheckSplineTransform = CheckSpline.WorldTransform;

			int SegmentIndex = -1;
			float SegmentAlpha = 0.0;
			SplineComputation::GetSegmentAlphaPlaneClosestToRelativeLocation(
				CheckSpline.ComputedSpline,
				CheckSplineTransform.InverseTransformPosition(WorldLocation),
				SegmentIndex,
				SegmentAlpha,
				CheckSplineTransform.InverseTransformVectorNoScale(ConstrainWorldPlaneNormal).GetSafeNormal(),
				BestPointDistanceSQ
			);

			if (SegmentIndex != -1)
			{
				BestSegmentIndex = SegmentIndex;
				BestSegmentAlpha = SegmentAlpha;
				BestComponent = CheckSpline;
			}
		}

	}
	else
	{
		BestComponent = Spline;

		FTransform CheckSplineTransform = Spline.WorldTransform;
		SplineComputation::GetSegmentAlphaPlaneClosestToRelativeLocation(
			Spline.ComputedSpline,
			CheckSplineTransform.InverseTransformPosition(WorldLocation),
			BestSegmentIndex,
			BestSegmentAlpha,
			CheckSplineTransform.InverseTransformVectorNoScale(ConstrainWorldPlaneNormal).GetSafeNormal(),
			BestPointDistanceSQ
		);
	}

	if (BestComponent != nullptr)
	{
		return FSplinePosition(
			BestComponent, 
			SplineComputation::GetSplineDistanceAtSegmentAlpha(
				BestComponent.ComputedSpline, BestSegmentIndex, BestSegmentAlpha),
			true);
	}
	else
	{
		return FSplinePosition();
	}
}

/**
 * Get the spline position on this spline at the specified distance.
 */
mixin FSplinePosition GetSplinePositionAtSplineDistance(UHazeSplineComponent Spline, float SplineDistance, bool bForwardFacing = true)
{
	return FSplinePosition(
		Spline,
		Math::Clamp(SplineDistance, 0.0, Spline.SplineLength),
		bForwardFacing = bForwardFacing,
	);
}

/**
 * Get the spline position that is approximately closest to the specified line segment in world space.
 * 
 * If bSearchConnections is true, this could also be a position on a different, connected spline.
 */
mixin FSplinePosition GetClosestSplinePositionToLineSegment(UHazeSplineComponent Spline, FVector WorldLineSegmentStart, FVector WorldLineSegmentEnd, bool bSearchConnections = true)
{
	UHazeSplineComponent BestComponent = nullptr;
	float BestPointDistanceSQ = MAX_flt;
	int BestSegmentIndex = 0;
	float BestSegmentAlpha = 0.0;

	if (bSearchConnections && Spline.SplineConnections.Num() != 0)
	{
		TArray<UHazeSplineComponent> AllSplines = Spline.GetAllLinkedSplines();

		for (UHazeSplineComponent CheckSpline : AllSplines)
		{
			// If the spline we're checking is completely further away than our current closest point,
			// we can ignore it - no point on it will be close enough.
			FVector SplineCenter = CheckSpline.WorldTransform.TransformPosition(CheckSpline.ComputedSpline.Bounds.Center);
			FVector ClosestToBounds = Math::ClosestPointOnLine(WorldLineSegmentStart, WorldLineSegmentEnd, SplineCenter);

			float DistanceToBounds = SplineCenter.Distance(ClosestToBounds) - CheckSpline.ComputedSpline.BoundsRadius;
			if (DistanceToBounds > 0.0 && Math::Square(DistanceToBounds) > BestPointDistanceSQ)
				continue;

			// Find the closest point on this spline and compare it to our current closest
			FTransform CheckSplineTransform = CheckSpline.WorldTransform;

			int SegmentIndex = -1;
			float SegmentAlpha = 0.0;
			SplineComputation::GetSegmentAlphaClosestToRelativeLineSegment(
				Spline.ComputedSpline,
				CheckSplineTransform.InverseTransformPosition(WorldLineSegmentStart),
				CheckSplineTransform.InverseTransformPosition(WorldLineSegmentEnd),
				SegmentIndex,
				SegmentAlpha,
				BestPointDistanceSQ
			);

			if (SegmentIndex != -1)
			{
				BestSegmentIndex = SegmentIndex;
				BestSegmentAlpha = SegmentAlpha;
				BestComponent = CheckSpline;
			}
		}

	}
	else
	{
		BestComponent = Spline;

		FTransform CheckSplineTransform = Spline.WorldTransform;
		SplineComputation::GetSegmentAlphaClosestToRelativeLineSegment(
			Spline.ComputedSpline,
			CheckSplineTransform.InverseTransformPosition(WorldLineSegmentStart),
			CheckSplineTransform.InverseTransformPosition(WorldLineSegmentEnd),
			BestSegmentIndex,
			BestSegmentAlpha,
			BestPointDistanceSQ
		);
	}

	if (BestComponent != nullptr)
	{
		return FSplinePosition(
			BestComponent, 
			SplineComputation::GetSplineDistanceAtSegmentAlpha(
				BestComponent.ComputedSpline, BestSegmentIndex, BestSegmentAlpha),
			true);
	}
	else
	{
		return FSplinePosition();
	}
}

/**
 * Get the spline position that is approximately closest to the specified line segment in world space,
 * distances are only counted on the specified plane.
 * 
 * If bSearchConnections is true, this could also be a position on a different, connected spline.
 */
mixin FSplinePosition GetPlaneConstrainedClosestSplinePositionToLineSegment(UHazeSplineComponent Spline, FVector WorldLineSegmentStart, FVector WorldLineSegmentEnd, FVector ConstrainWorldPlaneNormal, bool bSearchConnections = true)
{
	UHazeSplineComponent BestComponent = nullptr;
	float BestPointDistanceSQ = MAX_flt;
	int BestSegmentIndex = 0;
	float BestSegmentAlpha = 0.0;

	if (bSearchConnections && Spline.SplineConnections.Num() != 0)
	{
		TArray<UHazeSplineComponent> AllSplines = Spline.GetAllLinkedSplines();

		for (UHazeSplineComponent CheckSpline : AllSplines)
		{
			// If the spline we're checking is completely further away than our current closest point,
			// we can ignore it - no point on it will be close enough.
			FVector SplineCenter = CheckSpline.WorldTransform.TransformPosition(CheckSpline.ComputedSpline.Bounds.Center);
			FVector ClosestToBounds = Math::ClosestPointOnLine(WorldLineSegmentStart, WorldLineSegmentEnd, SplineCenter);

			float DistanceToBounds = SplineCenter.Distance(ClosestToBounds) - CheckSpline.ComputedSpline.BoundsRadius;
			if (DistanceToBounds > 0.0 && Math::Square(DistanceToBounds) > BestPointDistanceSQ)
				continue;

			// Find the closest point on this spline and compare it to our current closest
			FTransform CheckSplineTransform = CheckSpline.WorldTransform;

			int SegmentIndex = -1;
			float SegmentAlpha = 0.0;
			SplineComputation::GetSegmentAlphaPlaneConstrainedClosestToRelativeLineSegment(
				Spline.ComputedSpline,
				CheckSplineTransform.InverseTransformPosition(WorldLineSegmentStart),
				CheckSplineTransform.InverseTransformPosition(WorldLineSegmentEnd),
				SegmentIndex,
				SegmentAlpha,
				CheckSplineTransform.InverseTransformVectorNoScale(ConstrainWorldPlaneNormal).GetSafeNormal(),
				BestPointDistanceSQ
			);

			if (SegmentIndex != -1)
			{
				BestSegmentIndex = SegmentIndex;
				BestSegmentAlpha = SegmentAlpha;
				BestComponent = CheckSpline;
			}
		}

	}
	else
	{
		BestComponent = Spline;

		FTransform CheckSplineTransform = Spline.WorldTransform;
		SplineComputation::GetSegmentAlphaPlaneConstrainedClosestToRelativeLineSegment(
			Spline.ComputedSpline,
			CheckSplineTransform.InverseTransformPosition(WorldLineSegmentStart),
			CheckSplineTransform.InverseTransformPosition(WorldLineSegmentEnd),
			BestSegmentIndex,
			BestSegmentAlpha,
			CheckSplineTransform.InverseTransformVectorNoScale(ConstrainWorldPlaneNormal).GetSafeNormal(),
			BestPointDistanceSQ
		);
	}

	if (BestComponent != nullptr)
	{
		return FSplinePosition(
			BestComponent, 
			SplineComputation::GetSplineDistanceAtSegmentAlpha(
				BestComponent.ComputedSpline, BestSegmentIndex, BestSegmentAlpha),
			true);
	}
	else
	{
		return FSplinePosition();
	}
}