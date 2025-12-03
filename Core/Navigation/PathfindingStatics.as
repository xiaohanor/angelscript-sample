namespace Pathfinding
{
	UFUNCTION(Category = "Pathfinding")
	bool IsPathNear(FVector Location, FVector OtherLocation, float Range, float HeightTolerance = 100.0, FVector UpDir = FVector::UpVector)
	{
		FVector Diff = Location - OtherLocation;
		if  (UpDir == FVector::UpVector)
		{
			// World aligned up, most common case
			Diff.Z = Math::Max(0.0, Math::Abs(Diff.Z) - HeightTolerance); // Note that sign does not matter
			return Diff.SizeSquared() < Math::Square(Range);
		}

		// General case
		FVector Up = UpDir.IsNormalized() ? UpDir : UpDir.GetSafeNormal(); 
		float UpDist = Up.DotProduct(Diff);
		FVector Horizontaldiff = Diff - (Up * UpDist);
		Diff = Horizontaldiff + (Up * Math::Max(0.0, UpDist - HeightTolerance));// Note that sign does not matter
		return Diff.SizeSquared() < Math::Square(Range);
	}

	bool IsNearNavmesh(FVector Location, float HorizontalRange, float VerticalRange)
	{
		FVector Dummy;
		return FindNavmeshLocation(Location, HorizontalRange, VerticalRange, Dummy);	
	}

	// Return true if a location on the navmesh could be found which was within given range. If so, OutNavmeshLocation is set.
	bool FindNavmeshLocation(FVector Location, float HorizontalRange, float VerticalRange, FVector& OutNavmeshLocation)
	{
		// First try to find vertically projected location
		if (UNavigationSystemV1::ProjectPointToNavigation(Location, OutNavmeshLocation, nullptr, nullptr, FVector(4.0, 4.0, VerticalRange)))
			return true;
		
		// If no vertical projection, broaden search
		if (UNavigationSystemV1::ProjectPointToNavigation(Location, OutNavmeshLocation, nullptr, nullptr, FVector(HorizontalRange, HorizontalRange, VerticalRange)))
			return true;

		// No path location could be found
		return false;
	}

	bool StraightPathExists(FVector StartNavmeshLocation, FVector EndNavmeshLocation)
	{
		UNavigationPath Path = UNavigationSystemV1::FindPathToLocationSynchronously(StartNavmeshLocation, EndNavmeshLocation);
		if(Path == nullptr)
			return false;

		if(!Path.IsValid())
		{
			// We can get this when start is nav mesh identical to end.
			// This counts as having a path if both points are on navmesh.
			FVector StartProjected;
			if (!UNavigationSystemV1::ProjectPointToNavigation(StartNavmeshLocation, StartProjected, nullptr, nullptr, FVector(4.0, 4.0, 100.0)))
				return false;
			FVector EndProjected;
			if (!UNavigationSystemV1::ProjectPointToNavigation(EndNavmeshLocation, EndProjected, nullptr, nullptr, FVector(4.0, 4.0, 100.0)))
				return false;
			if (!StartProjected.IsWithinDist(EndProjected, 1.0))
				return false;
			return true;
		}

		// Path funnelling will ensure we only get two nodes when there are no corners to pass around
		if (Path.PathPoints.Num() != 2)
			return false; // Path was not straight 

		// Did path reach end?
		if (!Path.PathPoints.Last().IsWithinDist(EndNavmeshLocation, 1.0))
			return false;

		return true;
	}

	bool HasPath(FVector StartLocation, FVector EndLocation)
	{
		// FindPathToLocationSynchronously allows a slop of 250 units in vertically and 50 units horizontally, so Start and End need not strictly be nav mesh locations
		// TODO: Fix properly (or at least expose this)
		UNavigationPath Path = UNavigationSystemV1::FindPathToLocationSynchronously(StartLocation, EndLocation);
		if(Path == nullptr)
			return false;

		if(!Path.IsValid())
		{
			// We can get this when start is nav mesh identical to end.
			// This counts as having a path if both points are on navmesh.
			FVector StartProjected;
			if (!UNavigationSystemV1::ProjectPointToNavigation(StartLocation, StartProjected, nullptr, nullptr, FVector(4.0, 4.0, 100.0)))
				return false;
			FVector EndProjected;
			if (!UNavigationSystemV1::ProjectPointToNavigation(EndLocation, EndProjected, nullptr, nullptr, FVector(4.0, 4.0, 100.0)))
				return false;
			if (!StartProjected.IsWithinDist(EndProjected, 1.0))
				return false;
			return true;
		}

		// Did path reach end?
		if (!Path.PathPoints.Last().IsWithinDist(EndLocation, 1.0))
		{
			// Check that navmesh loca
			FVector EndProjected;
			if (!UNavigationSystemV1::ProjectPointToNavigation(EndLocation, EndProjected, nullptr, nullptr, FVector(4.0, 4.0, 100.0)))
				return false;
			if (!Path.PathPoints.Last().IsWithinDist(EndProjected, 1.0))		
				return false;
		}

		return true;
	}

	FVector FindLongestStraightPath(FVector FromLocation, float MaxDistance, float StartTolerance = 200.0, float DbgDur = 0.0)
	{
		FHazeNavmeshPoly FromPoly = Navigation::FindNearestPoly(FromLocation, StartTolerance);
		if (!FromPoly.IsValid())
			return FromLocation;

		// Depth first search since we don't care about direction
		TArray<FHazeNavmeshEdge> FromEdges;
		FromPoly.GetEdges(FromEdges);
		float LongestPartialSqr = 0.0;
		FVector BestPartialDest = FromLocation;
		for (FHazeNavmeshEdge Edge : FromEdges)
		{
			FVector Dest = FunnelLongestStraightPath(FromLocation, Edge, FromPoly, MaxDistance, Edge.Left, Edge.Right, DbgDur);
			if (!Dest.IsWithinDist(FromLocation, MaxDistance - 1.0))
				return Dest;

			// Couldn't reach the wanted MaxDistance, save destination it if it's the longest partial path
			float LengthSqr = FromLocation.DistSquared(Dest);		
			if (LengthSqr < LongestPartialSqr)
				continue;
			LongestPartialSqr = LengthSqr;
			BestPartialDest = Dest;
		}
		return BestPartialDest;
	}

	FVector FunnelLongestStraightPath(FVector FromLocation, FHazeNavmeshEdge PrevEdge, FHazeNavmeshPoly PrevPoly, float MaxDistance, FVector FunnelLeft, FVector FunnelRight, float DbgDur)
	{
		// Are we done yet?
		bool bLeftBeyond = !FromLocation.IsWithinDist(FunnelLeft, MaxDistance);
		bool bRightBeyond = !FromLocation.IsWithinDist(FunnelRight, MaxDistance);
		if (bLeftBeyond || bRightBeyond)
		{
			FLineSphereIntersection Intersection = Math::GetLineSegmentSphereIntersectionPoints(FunnelLeft, FunnelRight, FromLocation, MaxDistance);

			if (Intersection.IntersectionCount == 2)
				return GetLocationClampedNearOrigin((Intersection.MinIntersection + Intersection.MaxIntersection) * 0.5, FromLocation, MaxDistance);

			// Single intersection, one end is inside and one beyond, use intersection as this is the centermost location at wanted range
			if (Intersection.IntersectionCount == 1)
			{
				if (!ensure(Math::IsNearlyEqual(Intersection.MinIntersection.Distance(FromLocation), MaxDistance, 1.0)))	
					PrintToScreen("Blarg");
				return Intersection.MinIntersection;
			}

			// No intersection; if both ends are further away than required distance, use destination at wanted distance towards center
			if (bLeftBeyond && bRightBeyond)
				return GetLocationClampedNearOrigin((FunnelLeft + FunnelRight) * 0.5, FromLocation, MaxDistance);
		}

		// Both ends are within distance. If there's no poly on the other side of edge
		// we'll have to settle for the edge furthest away,
		if (!PrevEdge.Destination.IsValid())
		{
			float LeftDistSqr = FromLocation.DistSquared(FunnelLeft);
			float RightDistSqr = FromLocation.DistSquared(FunnelRight);
			const float ThresholdSqr = 1.01; // 1.1*1.1
			if (LeftDistSqr > RightDistSqr * ThresholdSqr)
				return FunnelLeft; 
			if (RightDistSqr > LeftDistSqr * ThresholdSqr)
				return FunnelRight;
			return (FunnelLeft + FunnelRight) * 0.5;
		}

		// Check if funnel is zero width
		if (FunnelLeft.IsWithinDist(FunnelRight, 0.1))
			return FunnelLeft;

		// Not done, continue searching edges out of destination poly
		TArray<FHazeNavmeshEdge> NextEdges;
		PrevEdge.Destination.GetEdges(NextEdges);
		FVector BestPartialDest = (FunnelLeft + FunnelRight) * 0.5; // Center of funnel if nothing else
		float LongestPartialSqr = 0.0;
		FVector LeftFunnelDir = (FunnelLeft - FromLocation).GetSafeNormal();
		FVector RightFunnelDir = (FunnelRight - FromLocation).GetSafeNormal();
		FVector FunnelNormal = LeftFunnelDir.CrossProduct(RightFunnelDir);
		FVector LeftFunnelInwards = LeftFunnelDir.CrossProduct(FunnelNormal);
		FVector RightFunnelInwards = -RightFunnelDir.CrossProduct(FunnelNormal);
		for (FHazeNavmeshEdge NextEdge : NextEdges)
		{
			// Don't go back
			if (NextEdge.Center.IsWithinDist(PrevEdge.Center, 1.0))
				continue;
			// There are weird edges from navmesh artifacts, double check with poly
			if (NextEdge.Destination.IsValid() && PrevPoly.Center.IsWithinDist(NextEdge.Destination.Center, 1.0))
				continue;

			// Is funnel overlapping edge?
			FVector ToEdgeLeft = (NextEdge.Left - FromLocation);
			FVector ToEdgeRight = (NextEdge.Right - FromLocation);
			TOptional<FVector> NextFunnelLeft = GetFunnelMovedToEdge(FunnelLeft, LeftFunnelInwards, ToEdgeLeft, NextEdge.Left, NextEdge.Right);
			if (!NextFunnelLeft.IsSet())
				continue; // Edge is wholly to the left of funnel
			TOptional<FVector> NextFunnelRight = GetFunnelMovedToEdge(FunnelRight, RightFunnelInwards, ToEdgeRight, NextEdge.Right, NextEdge.Left);
			if (!NextFunnelRight.IsSet())
				continue; // Edge is wholly to the right of funnel

			// Edge is at least partially within funnel, continue through edge				
			FVector Dest = FunnelLongestStraightPath(FromLocation, NextEdge, PrevEdge.Destination, MaxDistance, NextFunnelLeft.Value, NextFunnelRight.Value, DbgDur);
			if (!Dest.IsWithinDist(FromLocation, MaxDistance - 1.0))
				return Dest;

			// Couldn't reach the wanted MaxDistance, save destination it if it's the longest partial path
			float LengthSqr = FromLocation.DistSquared(Dest);		
			if (LengthSqr < LongestPartialSqr)
				continue;
			LongestPartialSqr = LengthSqr;
			BestPartialDest = Dest;
		}
		return BestPartialDest;
	}

	TOptional<FVector> GetFunnelMovedToEdge(FVector FunnelLoc, FVector FunnelInwardsNormal, FVector ToEdgeStart, FVector EdgeStart, FVector EdgeEnd)
	{
		if (ToEdgeStart.DotProduct(FunnelInwardsNormal) > 0.0)
		{
			// Edgestart is inside funnel, narrow funnel to that location
			return TOptional<FVector>(EdgeStart); 
		}

		// Edge starts is outside funnel (i.e. left edge is to the left of left funnel side or vices versa). 
		// Keep current width of funnel but move location to where funnel intersects edge.
		FVector FunnelIntersection;
		if (Math::IsLineSegmentIntersectingPlane(EdgeStart, EdgeEnd, FunnelInwardsNormal, FunnelLoc, FunnelIntersection))
			return TOptional<FVector>(FunnelIntersection);

		// Edge is wholly outside funnel
		return TOptional<FVector>();
	}


	// TODO: Move this to some other namespace
	FVector GetLocationClampedNearOrigin(FVector Location, FVector Origin, float Distance)
	{
		if (Distance < SMALL_NUMBER)
			return Origin;
		if (Location.IsWithinDist(Origin, Distance))
			return Location;
		return Origin + (Location - Origin).GetUnsafeNormal() * Distance; 
	}

	FVector GetOutwardsEdgeDirection(FHazeNavmeshEdge Edge, FVector UpVector)
	{
		return (Edge.Left - Edge.Right).GetSafeNormal().CrossProduct(UpVector);
	}
}

mixin void DrawDebugNavmeshPoly(const FHazeNavmeshPoly& Poly, FLinearColor Color = FLinearColor::White, float Thickness = 3.0, float Duration = 0.0)
{
	TArray<FVector> Verts;
	Poly.GetVertices(Verts);
	for (int i = 0; i < Verts.Num(); i++)
	{
		Debug::DrawDebugLine(Verts[i], Verts[(i + 1) % Verts.Num()], Color, Thickness, Duration);
	}
}
