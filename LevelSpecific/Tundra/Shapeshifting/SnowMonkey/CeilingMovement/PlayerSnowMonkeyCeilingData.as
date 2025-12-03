struct FTundraPlayerSnowMonkeyCeilingData
{
	UHazeSplineComponent Spline;
	UTundraPlayerSnowMonkeyCeilingClimbComponent ClimbComp;
	TArray<FTundraPlayerSnowMonkeyCeilingBlockingData> RelevantBlockingData;
	TArray<FTundraPlayerSnowMonkeyCeilingExclusiveData> RelevantExclusiveData;
	float SplineMeshWidth;
	float Pushback;
	FBox CeilingLocalBounds;
	FTransform CeilingTransform;
	float VerticalOffset;

	bool opEquals(const FTundraPlayerSnowMonkeyCeilingData& Other) const
	{
		return ClimbComp == Other.ClimbComp;
	}

	// True if the point's x/y location is within the ceiling, ignores z.
	bool IsPointWithinCeiling(FVector Point) const
	{
		FVector Dummy;
		bool bResult = ConstrainToSpline(Point, Dummy) || ConstrainToCube(Point, Dummy);
		return !bResult;
	}

	// If the point's x/y location is within the ceiling it will return 0.0. Otherwise it will return the distance to the closest point.
	float GetHorizontalDistanceToCeiling(FVector Point) const
	{
		FVector ClosestPoint;
		return GetHorizontalDistanceToCeiling(Point, ClosestPoint);
	}

	float GetHorizontalDistanceToCeiling(FVector Point, FVector& ClosestPoint) const
	{
		if(!ConstrainToCeiling(Point, ClosestPoint))
			return 0.0;

		return ClosestPoint.Distance(Point);
	}

	float GetDistanceToCeiling(FVector Point, FVector& ClosestPoint) const
	{
		ClosestPoint = GetClosestPointOnCeiling(Point);
		return Point.Distance(ClosestPoint);
	}

	float GetDistanceToCeiling(FVector Point) const
	{
		FVector ClosestPoint;
		return GetDistanceToCeiling(Point, ClosestPoint);
	}

	float GetVerticalDistanceToCeiling(FVector Point) const
	{
		FVector ClosestPoint = GetClosestPointOnCeiling(Point);
		return Math::Abs(Point.Z - ClosestPoint.Z);
	}

	FVector GetClosestPointOnCeiling(FVector Point) const
	{
		FVector ClosestPoint;
		ConstrainToCeiling(Point, ClosestPoint, true);
		return ClosestPoint;
	}

	// True if point should be constrained (is outside ceiling), will constrain the x/y coordinate, the z coordinate will be unchanged.
	bool ConstrainToCeiling(FVector Point, FVector& ClosestConstrainedPosition, bool bConstrainHeightAlso = false) const
	{
		return ConstrainToSpline(Point, ClosestConstrainedPosition, bConstrainHeightAlso) || ConstrainToCube(Point, ClosestConstrainedPosition, bConstrainHeightAlso);
	}

	// True if point should be constrained (is outside spline)
	private bool ConstrainToSpline(FVector Point, FVector& ClosestConstrainedPosition, bool bConstrainHeightAlso = false) const
	{
		if(Spline == nullptr)
			return false;

		float SplineDistance = Spline.GetClosestSplineDistanceToWorldLocation(Point);
		FTransform ClosestSplineTransform = Spline.GetWorldTransformAtSplineDistance(SplineDistance);
		FVector LocalPoint = ClosestSplineTransform.InverseTransformPosition(Point);
		FVector ConstrainDelta;

		bool bConstrain = false;

		if(SplineDistance < Pushback)
		{
			bConstrain = true;
			float Height = LocalPoint.Z;
			FTransform RelevantSplineTransform = Spline.GetWorldTransformAtSplineDistance(Pushback);
			FVector RelevantLocalPoint = RelevantSplineTransform.InverseTransformPosition(Point);
			RelevantLocalPoint.X = 0.0;
			RelevantLocalPoint.Z = Height;
			ConstrainDelta += RelevantSplineTransform.TransformPosition(RelevantLocalPoint) - Point;
		}

		if(SplineDistance > Spline.SplineLength - Pushback)
		{
			bConstrain = true;
			float Height = LocalPoint.Z;
			FTransform RelevantSplineTransform = Spline.GetWorldTransformAtSplineDistance(Spline.SplineLength - Pushback);
			FVector RelevantLocalPoint = RelevantSplineTransform.InverseTransformPosition(Point);
			RelevantLocalPoint.X = 0.0;
			RelevantLocalPoint.Z = Height;
			ConstrainDelta += RelevantSplineTransform.TransformPosition(RelevantLocalPoint) - Point;
		}

		float MaxLocalOffset = SplineMeshWidth - Pushback / ClosestSplineTransform.Scale3D.Y;
		if(LocalPoint.Y > MaxLocalOffset)
		{
			bConstrain = true;
			LocalPoint.Y = MaxLocalOffset;
			ConstrainDelta += ClosestSplineTransform.TransformPosition(LocalPoint) - Point;
		}

		if(LocalPoint.Y < -MaxLocalOffset)
		{
			bConstrain = true;
			LocalPoint.Y = -MaxLocalOffset;
			ConstrainDelta += ClosestSplineTransform.TransformPosition(LocalPoint) - Point;
		}

		FVector PointNoHeight = (Point + ConstrainDelta).PointPlaneProject(ClosestSplineTransform.Location, ClosestSplineTransform.Rotation.UpVector);
		FVector BlockerConstrainedPoint;
		if(ConstrainToBlockerComponents(PointNoHeight, BlockerConstrainedPoint))
		{
			FVector Delta = BlockerConstrainedPoint - PointNoHeight;
			ConstrainDelta += Delta;
			bConstrain = true;
		}

		FVector ExclusiveConstrainedPoint;
		if(ConstrainToExclusiveComponents(PointNoHeight, ExclusiveConstrainedPoint))
		{
			FVector Delta = ExclusiveConstrainedPoint - PointNoHeight;
			ConstrainDelta += Delta;
			bConstrain = true;
		}

		ClosestConstrainedPosition = Point + ConstrainDelta;

		if(bConstrainHeightAlso)
		{
			ClosestConstrainedPosition = ClosestConstrainedPosition.PointPlaneProject(ClosestSplineTransform.Location + ClosestSplineTransform.Rotation.UpVector * VerticalOffset, ClosestSplineTransform.Rotation.UpVector);
		}

		return bConstrain;
	}

	// True if point should be constrained (is outside cube)
	private bool ConstrainToCube(FVector Point, FVector& ClosestConstrainedPosition, bool bConstrainHeightAlso = false) const
	{
		if(Spline != nullptr)
			return false;

		FVector BoundsWorldPoint = CeilingTransform.TransformPosition(CeilingLocalBounds.Center);
		FTransform AdjustedTransform = FTransform(CeilingTransform.Rotation, BoundsWorldPoint, CeilingTransform.Scale3D);

		FVector LocalPoint = AdjustedTransform.InverseTransformPosition(Point);
		FVector CeilingExtents = CeilingLocalBounds.Extent;
		FVector PushbackExtents = FVector(CeilingExtents.X - (Pushback / CeilingTransform.Scale3D.X), CeilingExtents.Y - (Pushback / CeilingTransform.Scale3D.Y), CeilingExtents.Z);

		bool bConstrain = false;

		if(LocalPoint.X > PushbackExtents.X || LocalPoint.X < -PushbackExtents.X)
		{
			bConstrain = true;
			LocalPoint.X = PushbackExtents.X * Math::Sign(LocalPoint.X);
		}

		if(LocalPoint.Y > PushbackExtents.Y || LocalPoint.Y < -PushbackExtents.Y)
		{
			bConstrain = true;
			LocalPoint.Y = PushbackExtents.Y * Math::Sign(LocalPoint.Y);
		}

		FVector PointNoHeight = LocalPoint;
		PointNoHeight.Z = -CeilingExtents.Z;
		PointNoHeight = AdjustedTransform.TransformPosition(PointNoHeight);
		FVector BlockerConstrainedPoint;
		if(ConstrainToBlockerComponents(PointNoHeight, BlockerConstrainedPoint))
		{
			FVector Delta = BlockerConstrainedPoint - PointNoHeight;
			FVector LocalDelta = AdjustedTransform.InverseTransformVector(Delta);
			LocalPoint += LocalDelta;
			bConstrain = true;
		}

		FVector ExclusiveConstrainedPoint;
		if(ConstrainToExclusiveComponents(PointNoHeight, ExclusiveConstrainedPoint))
		{
			FVector Delta = ExclusiveConstrainedPoint - PointNoHeight;
			FVector LocalDelta = AdjustedTransform.InverseTransformVector(Delta);
			LocalPoint += LocalDelta;
			bConstrain = true;
		}

		if(bConstrainHeightAlso)
		{
			bConstrain = true;
			LocalPoint.Z = -CeilingExtents.Z;
			LocalPoint.Z += VerticalOffset / AdjustedTransform.Scale3D.Z;
		}

		if(!bConstrain)
		{
			ClosestConstrainedPosition = Point;
			return false;
		}

		ClosestConstrainedPosition = AdjustedTransform.TransformPosition(LocalPoint);
		return true;
	}

	private bool ConstrainToBlockerComponents(FVector Point, FVector&out ConstrainedPoint) const
	{
		for(int i = 0; i < RelevantBlockingData.Num(); i++)
		{
			FTundraPlayerSnowMonkeyCeilingBlockingData Data = RelevantBlockingData[i];
			if(Data.IsPointInside(Point))
			{
				ConstrainedPoint = Data.GetClosestPointOutsideBlocker(Point);
				return true;
			}
		}

		return false;
	}

	private bool ConstrainToExclusiveComponents(FVector Point, FVector&out ConstrainedPoint) const
	{
		for(int i = 0; i < RelevantExclusiveData.Num(); i++)
		{
			FTundraPlayerSnowMonkeyCeilingExclusiveData Data = RelevantExclusiveData[i];
			if(!Data.IsPointInside(Point))
			{
				ConstrainedPoint = Data.GetClosestPointInsideBlocker(Point);
				return true;
			}
		}

		return false;
	}
}