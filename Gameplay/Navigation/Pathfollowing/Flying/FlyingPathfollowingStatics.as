mixin void DrawDebug(FNavigationPath Path, FVector DrawOffset, FLinearColor Color)
{
	FVector PrevLoc = Path.Points[0];
	for (int i = 1; i < Path.Points.Num(); i++)
	{
		FVector Loc = Path.Points[i];
		Debug::DrawDebugLine(PrevLoc + DrawOffset, Loc + DrawOffset, Color, 1.0, 0.0);
		PrevLoc = Loc;
	}
}

mixin void DrawDebugTurns(FNavigationPath Path, float TurnRadius, FLinearColor Color)
{
	if (Path.Points.Num() < 2)
		return;

	// Find the pivots for turn points
	TArray<FVector> Pivots;
	Pivots = Path.Points; 
	TArray<float> TurnRadii;
	TurnRadii.SetNumZeroed(Path.Points.Num());
	for (int i = 1; i < Path.Points.Num() - 1; i++)
	{
		FVector Cur = Path.Points[i];
		FVector FromPrev = (Cur - Path.Points[i - 1]).GetSafeNormal();
		FVector ToNext = (Path.Points[i + 1] - Cur).GetSafeNormal();
		if (FromPrev.DotProduct(ToNext) > 0.99)
			continue; 

		// Adjust turnradius as necessary
		float MinDistSqr = Math::Min((Cur - Path.Points[i - 1]).SizeSquared(), (Path.Points[i + 1] - Cur).SizeSquared());
		if (MinDistSqr > Math::Square(TurnRadius * 2.0))
			TurnRadii[i] = TurnRadius; // More than double the diameter, use standard turn radius
		else
			TurnRadii[i] = Math::Sqrt(MinDistSqr) * 0.5;

		// Curved path, replace pivot
		FVector MidDir = (-FromPrev + ToNext).GetSafeNormal();
		Pivots[i] = Cur + MidDir * TurnRadii[i];

		Debug::DrawDebugCircle(Pivots[i], TurnRadii[i], 12, Color * 0.3f, 0, MidDir, MidDir.CrossProduct(MidDir.CrossProduct(FromPrev)).GetSafeNormal());
		Debug::DrawDebugLine(Cur, Pivots[i], Color * 0.5f, 0);
	}
	Pivots.Last() = Path.Points.Last();

	TArray<FVector> Points;
	for (int i = 0; i < Pivots.Num(); i++)
	{
		if (Path.Points[i] == Pivots[i])
		{
			// Start, end or straight, no pivot needed
			Points.Add(Path.Points[i]);
			continue;
		}
		
		// Add turn circle entry point, current point itself and exit point
		FVector Cur = Path.Points[i];
		FVector PivotToCur = (Cur - Pivots[i]);

		// Entry point on turn circle is orthogonal to direction from previous point, i.e. on it's plane
		FVector FromPrev = (Cur - Path.Points[i - 1]);
		FVector PivotToEntry = PivotToCur.VectorPlaneProject(FromPrev.GetSafeNormal()).GetSafeNormal() * TurnRadii[i];
		Points.Add(Pivots[i] + PivotToEntry);
		Points.Add(Pivots[i] + (PivotToCur + PivotToEntry).GetSafeNormal() * TurnRadii[i]); // Additional point for smoother curve

		Points.Add(Cur);

		FVector ToNext = (Path.Points[i + 1] - Cur);
		FVector PivotToExit = PivotToCur.VectorPlaneProject(ToNext.GetSafeNormal()).GetSafeNormal() * TurnRadii[i];
		Points.Add(Pivots[i] + (PivotToCur + PivotToExit).GetSafeNormal() * TurnRadii[i]); // Additional point for smoother curve
		Points.Add(Pivots[i] + PivotToExit);

		// TODO: Note that if we go straight back, then plane projection won't work. This shouldn't happen, but handle anyway (remove points as needed) 
	}

	for (int i = 1; i < Points.Num(); i++)
	{
		Debug::DrawDebugLine(Points[i - 1], Points[i], Color, 2.f);
	}
}

mixin void DrawDebugSpline(FNavigationPath Path, FLinearColor Color = FLinearColor::LucBlue)
{
	if (Path.Points.Num() < 2)
		return;

	// Debug draw for now
	FHazeRuntimeSpline Spline;
	Spline.CustomCurvature = 1;
	Spline.SetPoints(Path.Points);

	TArray<FVector> Locs;
	Spline.GetLocations(Locs, Path.Points.Num() * 20);
	for (int i = 1; i < Locs.Num(); i++)
	{
		Debug::DrawDebugLine(Locs[i - 1], Locs[i], Color, 4);
	}
}

mixin void DrawDebugPath(TArray<FHazeNavOctreePathNode> OctreePath)
{
	for (FHazeNavOctreePathNode Node : OctreePath)
	{
		Debug::DrawDebugBox(Node.Center, FVector(Node.HalfWidth, Node.HalfWidth, Node.HalfHeight), FRotator::ZeroRotator, FLinearColor::Yellow * 0.3f, 0.f, 0.f);
	}
}

struct FNavOctreePortal 
{
	TArray<FVector> Corners;

	private FVector Normal;
	private int iAxis = 0;
	private int iSide = 1; 
	private int iUp = 2;

	bool bDebug = false;

	FVector GetNormal()
	{
		return Normal;
	}

	void SetNormal(FVector _Normal)
	{
		Normal = _Normal;

		// Note that plane normal is axis aligned
		check(Normal != FVector::ZeroVector);
		check((Normal.X == 0.0 && Normal.Y == 0.0) || (Normal.X == 0.0 && Normal.Z == 0.0) || (Normal.Y == 0.0 && Normal.Z == 0.0));
		iAxis = (Normal.X != 0.0) ? 0 : (Normal.Y != 0.0) ? 1 : 2;
		iSide = 1 - Math::IntegerDivisionTrunc(iAxis, 2) - (iAxis % 2); 	// 0 -> 1, 1 or 2 -> 0 
		iUp = 2 - Math::IntegerDivisionTrunc(iAxis, 2); 					// 0 or 1 -> 2, 2 -> 1
	}

	FVector GetCenter() const property 
	{
		if (Corners.Num() == 0)
			return FVector::ZeroVector;

		FVector Total =	FVector::ZeroVector;
		for (FVector Corner : Corners)
		{
			Total += Corner;
		}
		return Total / float(Corners.Num());
	}

	bool FunnelMerge(FNavOctreePortal OtherPortal, FVector FunnelOrigin)
	{
		if (!ensure((Corners.Num() > 0) && (OtherPortal.Corners.Num() > 0)))
			return false;
		if (Corners.Num() == 2)
			return false; // We need area to merge
		
		// Project our corners onto other portal plane along lines from the funnel origin
		FNavOctreePortal ProjectedPortal;
		ProjectedPortal.SetNormal(OtherPortal.Normal);
		if (!OtherPortal.FunnelProject(FunnelOrigin, Corners, ProjectedPortal.Corners))
			return false;
		int nOwnCorners = ProjectedPortal.Corners.Num();
																								if (bDebug) ProjectedPortal.DrawDebug(FLinearColor::DPink, 0.0);
		// Get any of the other portal's corners inside this (projected) portal
		TArray<int> OtherInsideCorners;
		for (int i = 0; i < OtherPortal.Corners.Num(); i++)
		{
			if (ProjectedPortal.IsPointInside(OtherPortal.Corners[i]))
				OtherInsideCorners.Add(i);
		}
		int nOtherInside = OtherInsideCorners.Num();

		// Get any of our corners inside the other portal
		TArray<int> OwnInsideCorners;
		for (int i = 0; i < nOwnCorners; i++)
		{
			if (OtherPortal.IsPointInside(ProjectedPortal.Corners[i]))
				OwnInsideCorners.Add(i);
		}
		int nOwnInside = OwnInsideCorners.Num();

		if ((nOtherInside == 0) && (nOwnInside == 0)) 
		{
			// No overlapping points, most likely we can't merge.   
			// TODO: There are edge cases where we get overlaps which we can only find 
			// by edge to edge intersection tests. The extra cost might not warrant the 
			// few cases where this will occur though, we do not need perfect results.
			return false;	
		}

		// We can reach the other portal, move funnel end there!
		SetNormal(OtherPortal.Normal);			

		if (nOtherInside == OtherPortal.Corners.Num())
		{
			// Other is fully inside this, we just narrow funnel to other
			Corners = OtherPortal.Corners;
			return true;
		}

		if (nOwnInside == nOwnCorners)
		{
			// We're fully inside other, use our projected corners
			Corners = ProjectedPortal.Corners;
			return true;
		} 

		// Other portal overlaps with us, find intersections and add those to any overlapping points
		// Note that we will have at least three projected corners, see above early out, and will usually not gain more than one extra
		Corners.Empty(Corners.Num() + 1);
		ProjectedPortal.AddInsidePointsAndIntersections(OwnInsideCorners, OtherPortal, Corners);

		if (nOwnInside > 0)
		{
			// We had inside corners, so all intersections have been added. We just have to add the other's inside corners.
			// TODO: Order corners if necessary (haven't found any misordered yet, but there should be some cases...)
			for (int iOtherInside : OtherInsideCorners)
			{
				Corners.Add(OtherPortal.Corners[iOtherInside]);
			}
		}
		else if (nOtherInside > 0)
		{
			// No own inside corners, add the other portals inside corners and it's intersections with our projection
			OtherPortal.AddInsidePointsAndIntersections(OtherInsideCorners, ProjectedPortal, Corners);			
		}

		// TODO: There are some cases where an edge between two outside corners intersect the other portal twice
		// which are not handled. Invesitigate if the cost of detecting those is worth the slightly better result.

		return true;
	}

	bool FunnelProject(FVector FunnelOrigin, TArray<FVector> Vertices, TArray<FVector>& ProjectedVertices) const
	{
		// Portals are axis aligned, so we can simplify
		float Base = Corners[0][iAxis];
		ProjectedVertices.Empty(Vertices.Num());
		for (int i = 0; i < Vertices.Num(); i++)
		{
			FVector FromOrigin = Vertices[i] - FunnelOrigin;
			if (Math::IsNearlyZero(FromOrigin[iAxis]))
			{
				// Can't project, as vertex is at the same height along portal normal as origin
				// Move slighty along most non-orthogonal adjoining edge.
				FVector ToPrev = Vertices[(i - 1 + Vertices.Num()) % Vertices.Num()] - Vertices[i];
				FVector ToNext = Vertices[(i + 1) % Vertices.Num()] - Vertices[i];
				if (Math::IsNearlyZero(ToPrev[iAxis] * 0.1) && Math::IsNearlyZero(ToNext[iAxis] * 0.1))
					FromOrigin[iAxis] = Normal[iAxis]; // Edge case, just move along normal
				else if (Math::Abs(ToPrev[iAxis]) > Math::Abs(ToNext[iAxis]))
					FromOrigin += ToPrev * 0.1; 
				else
					FromOrigin += ToNext * 0.1; 
			}
			float Factor = (Base - Vertices[i][iAxis]) / FromOrigin[iAxis];
			if (Factor < -1.0)
				return false; // Projecting behind funnel origin

			ProjectedVertices.Add(Vertices[i] + FromOrigin * Factor);
		}
		return true;
	}

	bool IsPointInside(FVector Point) const
	{
		// Algorithm using Jordan curve theorem (e.g. https://wrf.ecse.rpi.edu//Research/Short_Notes/pnpoly.html)
		// This assumes we only test points within our portal plane 
		bool Result = false;
		for (int i = 0; i < Corners.Num(); i++)
		{
			int j = (i + 1) % Corners.Num();
			if (((Corners[i][iUp] >= Point[iUp]) != (Corners[j][iUp] >= Point[iUp])) && 
				((Point[iSide] - Corners[i][iSide]) <= (Corners[j][iSide] - Corners[i][iSide]) * (Point[iUp] - Corners[i][iUp]) / (Corners[j][iUp] - Corners[i][iUp])))
			{
				Result = !Result;				
			}
		}
		return Result;
	}

	private void AddInsidePointsAndIntersections(TArray<int> iInsides, FNavOctreePortal OtherPortal, TArray<FVector>& OutNewCorners) const
	{
		int nInside = iInsides.Num();
		int nCorners = Corners.Num();
		for (int i = 0; i < nInside; i++)
		{
			int iCur = iInsides[i];

			// If previous corner was outside, add intersection of line from that corner to this with the other portal
			int iPrev = iInsides[(i - 1 + nInside) % nInside];
			FVector PrevIntersection;
			if ((((iPrev + 1) % nCorners) != iCur) && OtherPortal.FindEndmostIntersection(Corners[(iCur - 1 + nCorners) % nCorners], Corners[iCur], PrevIntersection, 1))
				OutNewCorners.Add(PrevIntersection);

			// Add current corner 
			OutNewCorners.Add(Corners[iCur]);

			// If next corner is outside, add intersection
			int iNext = iInsides[(i + 1) % nInside];
			FVector NextIntersection;
			if ((((iCur + 1) % nCorners) != iNext) && OtherPortal.FindEndmostIntersection(Corners[iCur], Corners[(iCur + 1) % nCorners], NextIntersection, 1))
				OutNewCorners.Add(NextIntersection);
		}
	}

	private bool FindEndmostIntersection(FVector LineStart, FVector LineEnd, FVector& OutIntersection, int AssumedMaxIntersections) const
	{
		int nCorners = Corners.Num();
		if (nCorners < 2)
			return false;

		int nIntersections = 0;
		float ClosestEndDistSqr = BIG_NUMBER;
		FVector Line = LineEnd - LineStart;
		FVector PrevCorner = Corners.Last();
		for (int i = 0; i < nCorners; i++)
		{
			FVector Edge = Corners[i] - PrevCorner;
			float EdgeFactor = (-Line[iUp] * (LineStart[iSide] - PrevCorner[iSide]) + Line[iSide] * (LineStart[iUp] - PrevCorner[iUp]));
			float LineFactor = (Edge[iSide] * (LineStart[iUp] - PrevCorner[iUp])) - (Edge[iUp] * (LineStart[iSide] - PrevCorner[iSide]));
			float Denominator = (-Edge[iSide] * Line[iUp] + Edge[iUp] * Line[iSide]);
			if (Denominator < 0.0)
			{
				EdgeFactor *= -1.0;
				LineFactor *= -1.0;
				Denominator *= -1.0;
			}
			// We ignore lines on top of each other
			if ((EdgeFactor > 0.0) && (EdgeFactor < Denominator) && (LineFactor > 0.0) && (LineFactor < Denominator)) 
			{
				// Intersection found
				float Factor = LineFactor / Denominator;
				FVector Intersection;
				Intersection[iSide] = LineStart[iSide] + Factor * Line[iSide];
				Intersection[iUp] = LineStart[iUp] + Factor * Line[iUp];
				Intersection[iAxis] = Corners[i][iAxis]; 
				float DistSqr = Intersection.DistSquared(LineEnd);
				if (DistSqr < ClosestEndDistSqr)
				{
					ClosestEndDistSqr = DistSqr;	
					OutIntersection = Intersection;
				}
				nIntersections++;
				if (nIntersections == AssumedMaxIntersections)
					return true; // Convex poly, so never more than two intersections
			}

			PrevCorner = Corners[i];
		}
		return (nIntersections > 0);
	}

	FVector GetNextFunnelOrigin(FVector FunnelOrigin, FNavOctreePortal NextPortal)
	{
		check(Corners.Num() > 0);

		// Find the point on this portal closest to the next portal
		// First, find closest point in portal plane from origin to next portal
		FVector ClosestOnNext = NextPortal.GetClosestPointOnPortal(FunnelOrigin); 

		// Three cases:
		// 1. Origin is inside next portal in our plane
		if (Math::IsNearlyEqual(FunnelOrigin[iSide], ClosestOnNext[iSide]) && Math::IsNearlyEqual(FunnelOrigin[iUp], ClosestOnNext[iUp]))
		{
			// Use closest location on this portal
			return GetClosestPointOnPortal(FunnelOrigin); 
		}

		// 2. Line to closest point (in portal plane) travels through this portal.
		FVector Intersection; 		
		if (FindEndmostIntersection(FunnelOrigin, ClosestOnNext, Intersection, 2)) // Convex poly, so never more than two
		{
			// Use intersection closest to next portal
		 	return Intersection; 
		}

		// 3. Line to closest point passes outside portal
		// Use point on plane closest to line. 
		// TODO: There might be cases where it would be closer to use intersection of point reflected in closest edge, investigate
		float Numerator = Corners[0][iAxis] - FunnelOrigin[iAxis];
		float Denominator = ClosestOnNext[iAxis] - FunnelOrigin[iAxis];
		FVector LineClosest;
		if ((Numerator > Denominator) || !ensure(Denominator > SMALL_NUMBER))
			LineClosest = ClosestOnNext;
		else if (Numerator < 0.0)
			LineClosest = FunnelOrigin;
		else
			LineClosest = FunnelOrigin + ((ClosestOnNext - FunnelOrigin) * (Numerator / Denominator));
		return GetClosestPointOnPortal(LineClosest);
	}

	FVector GetClosestPointOnPortal(FVector Origin) const
	{
		check(Corners.Num() > 0);
		if (Corners.Num() < 2)
			return Corners[0];		
		FVector ClosestPoint;
		float ClosestDistSqr = BIG_NUMBER;
		FVector PrevCorner = Corners.Last();
		int nOnEdge = 0;
		for (int i = 0; i < Corners.Num(); i++)
		{
			// Find edge intersection with line orthogonal to edge through origin
			FVector Edge = Corners[i] - PrevCorner;
			float EdgeFactor = Edge.DotProduct(Origin - PrevCorner);
			float Denominator = Edge.SizeSquared();

			FVector ClosestOnEdge;
			if (EdgeFactor < 0.0 || Math::IsNearlyZero(Denominator)) 
			{
				// Before edge
				ClosestOnEdge = PrevCorner;
			} 
			else if (EdgeFactor > Denominator)
			{
				// After Edge
				ClosestOnEdge = Corners[i];
			}
			else
			{
				// Intersection found on edge
				float Factor = EdgeFactor / Denominator;
				ClosestOnEdge[iSide] = PrevCorner[iSide] + Factor * Edge[iSide];
				ClosestOnEdge[iUp] = PrevCorner[iUp] + Factor * Edge[iUp];
				ClosestOnEdge[iAxis] = PrevCorner[iAxis];
				nOnEdge++;
			}

			float DistSqr = ClosestOnEdge.DistSquared(Origin);
			if (DistSqr < ClosestDistSqr)
			{
				ClosestPoint = ClosestOnEdge;
				ClosestDistSqr = DistSqr;
			}

			PrevCorner = Corners[i];
		}
		if (nOnEdge == Corners.Num())
		{
			// Inside portal
			ClosestPoint[iUp] = Origin[iUp];
			ClosestPoint[iSide] = Origin[iSide];
		}
		return ClosestPoint;
	}

	void DrawDebug(FLinearColor Color, float Thickness, float InwardsMove = 0.0)
	{
		if (Corners.Num() < 2)
			return;
			
		for (int i = 0; i < Corners.Num(); i++)
		{
			FVector Start = Corners[i] + (Center - Corners[i]).GetSafeNormal() * InwardsMove;
			FVector End = Corners[(i + 1) % Corners.Num()] + (Center - Corners[(i + 1) % Corners.Num()]).GetSafeNormal() * InwardsMove;
			Debug::DrawDebugLine(Start, End, Color, Thickness);
		}
	}	
}

mixin void FunnelPath(TArray<FHazeNavOctreePathNode> OctreePath, FVector Start, FVector Destination, float EdgeBuffer, FNavigationPath& OutFunneledPath)
{
	OutFunneledPath.Points.Empty(OctreePath.Num() + 2);
	if (OctreePath.Num() < 2)
	{
		// We start and end within the same node. Convex, so go straight.
		OutFunneledPath.Points.Add(Start);
		OutFunneledPath.Points.Add(Destination);
		return;
	}
	
	// Traverse rectangular portals in between nodes
	const float SizeSlop = 0.01;
	TArray<FNavOctreePortal> Portals;
	Portals.SetNum(OctreePath.Num() - 1);	
	for (int iPortal = 0; iPortal < Portals.Num(); iPortal++)
	{
		// Check which face of octree node we travel through
		// Note that we can only use abs size comparison for horizontals, not vertically, since node height may differ from width.
		FVector PrevToNext = OctreePath[iPortal + 1].Center - OctreePath[iPortal].Center;
		FVector Normal = FVector::ZeroVector;
		if (Math::IsNearlyEqual(OctreePath[iPortal + 1].HalfHeight + OctreePath[iPortal].HalfHeight, Math::Abs(PrevToNext.Z), SizeSlop))
			Normal.Z = Math::Sign(PrevToNext.Z); // Top/bottom face
		else if (Math::Abs(PrevToNext.X) > Math::Abs(PrevToNext.Y))  
			Normal.X = Math::Sign(PrevToNext.X); // Forward/backward face
		else 
			Normal.Y = Math::Sign(PrevToNext.Y); // Right/left face
		Portals[iPortal].SetNormal(Normal);

		// Portal center is offset from the smallest node center 
		FVector Offset = Normal;
		int iSmallest = iPortal;
		if (OctreePath[iPortal + 1].HalfWidth < OctreePath[iPortal].HalfWidth)
		{
			iSmallest = iPortal + 1;
			Offset *= -1.0;
		}
		float HalfHeight = OctreePath[iSmallest].HalfHeight;
		float HalfWidth = OctreePath[iSmallest].HalfWidth;
		Offset *= FVector(HalfWidth, HalfWidth, HalfHeight);
		FVector PortalCenter = OctreePath[iSmallest].Center + Offset;

		// The four corners	of the traversed node face is moved inwards	to make sure we have space to move
		FVector PortalUp = FVector::UpVector * Math::Max(HalfHeight - EdgeBuffer, 0.0);
		FVector PortalRight = FVector::ForwardVector * Math::Max(HalfWidth - EdgeBuffer, 0.0);
		if (Normal.Z != 0.0)
			PortalUp = FVector::RightVector * Math::Max(HalfWidth - EdgeBuffer, 0.0);
		if (Normal.X != 0.0)
			PortalRight = FVector::RightVector * Math::Max(HalfWidth - EdgeBuffer, 0.0);

		Portals[iPortal].Corners.SetNum(4);
		Portals[iPortal].Corners[0] = PortalCenter + PortalUp + PortalRight;
		Portals[iPortal].Corners[1] = PortalCenter + PortalUp - PortalRight;
		Portals[iPortal].Corners[2] = PortalCenter - PortalUp - PortalRight;
		Portals[iPortal].Corners[3] = PortalCenter - PortalUp + PortalRight;
	}

	// Now test the corners of portals using a funnel made from the portals  
	// minimum polygon intersection, as viewed from each funnel origin
	FVector FunnelOrigin = Start;
	FNavOctreePortal FunnelPortal = Portals[0];
	int iPortal = 0;
	while (iPortal < Portals.Num())
	{																						
		OutFunneledPath.Points.Add(FunnelOrigin);
		int iTest = iPortal + 1;
		for (; iTest < Portals.Num(); iTest++)
		{																								
			if (FunnelPortal.FunnelMerge(Portals[iTest], FunnelOrigin))
				continue; // Intersection found, keep funnelling

			// No intersection, start a new funnel from best point in current funnel end 
			// (i.e. last portal that we could reach)
			FunnelOrigin = FunnelPortal.GetNextFunnelOrigin(FunnelOrigin, Portals[iTest]);
			FunnelPortal = Portals[iTest];
			break;
		}
		iPortal = iTest;
	}
	// Finally check if funnel extends all the way to destination
	FNavOctreePortal DestinationPortal;
	DestinationPortal.SetNormal(FunnelPortal.GetNormal());
	DestinationPortal.Corners.Add(Destination);
	if (!FunnelPortal.FunnelMerge(DestinationPortal, FunnelOrigin))
	{
		// Nope, need to add one more point
		OutFunneledPath.Points.Add(FunnelPortal.GetNextFunnelOrigin(FunnelOrigin, DestinationPortal)); 
	}
	OutFunneledPath.Points.Add(Destination);
}

mixin void DrawDebugFunnelling(TArray<FHazeNavOctreePathNode> OctreePath, FVector Start, FVector Destination)
{
	if (OctreePath.Num() < 2)
		return;

	const float BufferSize = 40.0;
	const float SizeSlop = 0.01;
	
	// Traverse rectangular portals in between nodes
	TArray<FNavOctreePortal> Portals;
	Portals.SetNum(OctreePath.Num() - 1);	
	for (int iPortal = 0; iPortal < Portals.Num(); iPortal++)
	{
		// Check which face of octree node we travel through
		// Note that we can only use abs size comparison for horizontals, not vertically, since node height may differ from width.
		FVector PrevToNext = OctreePath[iPortal + 1].Center - OctreePath[iPortal].Center;
		FVector Normal = FVector::ZeroVector;
		if (Math::IsNearlyEqual(OctreePath[iPortal + 1].HalfHeight + OctreePath[iPortal].HalfHeight, Math::Abs(PrevToNext.Z), SizeSlop))
			Normal.Z = Math::Sign(PrevToNext.Z); // Top/bottom face
		else if (Math::Abs(PrevToNext.X) > Math::Abs(PrevToNext.Y))  
			Normal.X = Math::Sign(PrevToNext.X); // Forward/backward face
		else 
			Normal.Y = Math::Sign(PrevToNext.Y); // Right/left face
		Portals[iPortal].SetNormal(Normal);

		// Portal center is offset from the smallest node center 
		FVector Offset = Normal;
		int iSmallest = iPortal;
		if (OctreePath[iPortal + 1].HalfWidth < OctreePath[iPortal].HalfWidth)
		{
			iSmallest = iPortal + 1;
			Offset *= -1.0;
		}
		float HalfHeight = OctreePath[iSmallest].HalfHeight;
		float HalfWidth = OctreePath[iSmallest].HalfWidth;
		Offset *= FVector(HalfWidth, HalfWidth, HalfHeight);
		FVector PortalCenter = OctreePath[iSmallest].Center + Offset;

		// The four corners	of the traversed node face is moved inwards	to make sure we have space to move
		FVector PortalUp = FVector::UpVector * Math::Max(HalfHeight - BufferSize, 0.0);
		FVector PortalRight = FVector::ForwardVector * Math::Max(HalfWidth - BufferSize, 0.0);
		if (Normal.Z != 0.0)
			PortalUp = FVector::RightVector * Math::Max(HalfWidth - BufferSize, 0.0);
		if (Normal.X != 0.0)
			PortalRight = FVector::RightVector * Math::Max(HalfWidth - BufferSize, 0.0);

		Portals[iPortal].Corners.SetNum(4);
		Portals[iPortal].Corners[0] = PortalCenter + PortalUp + PortalRight;
		Portals[iPortal].Corners[1] = PortalCenter + PortalUp - PortalRight;
		Portals[iPortal].Corners[2] = PortalCenter - PortalUp - PortalRight;
		Portals[iPortal].Corners[3] = PortalCenter - PortalUp + PortalRight;
	}

	// Now test the corners of portals using a funnel made from the portals  
	// minimum polygon intersection, as viewed from each funnel origin
	FNavigationPath FunneledPath;
	FVector FunnelOrigin = Start;
	FNavOctreePortal FunnelPortal = Portals[0];
	int iPortal = 0;
	while (iPortal < Portals.Num())
	{																						FunnelPortal.bDebug = false;			
		FunneledPath.Points.Add(FunnelOrigin);
		int iTest = iPortal + 1;
		for (; iTest < Portals.Num(); iTest++)
		{																					if (FunnelPortal.bDebug) FunnelPortal.DrawDebug(FLinearColor::Green, 1.0, 1.0);			
			if (FunnelPortal.FunnelMerge(Portals[iTest], FunnelOrigin))
				continue; // Intersection found, keep funnelling
																							if (FunnelPortal.bDebug) FunnelPortal.DrawDebug(FLinearColor::Blue, 2.0, 0.0);			
			// No intersection, start a new funnel from best point in current funnel end 
			// (i.e. last portal that we could reach)
			FunnelOrigin = FunnelPortal.GetNextFunnelOrigin(FunnelOrigin, Portals[iTest]);
			FunnelPortal = Portals[iTest];
			break;
		}
		iPortal = iTest;
	}
	// Finally check if funnel extends all the way to destination
	FNavOctreePortal DestinationPortal;
	DestinationPortal.Corners.Add(Destination);
	DestinationPortal.SetNormal(FunnelPortal.GetNormal()); // Is this correct?
	if (!FunnelPortal.FunnelMerge(DestinationPortal, FunnelOrigin))
	{
		// Nope, need to add one more point
		FunneledPath.Points.Add(FunnelPortal.GetNextFunnelOrigin(FunnelOrigin, DestinationPortal)); 
	}
	FunneledPath.Points.Add(Destination);
																							FunneledPath.DrawDebugSpline(FLinearColor::Purple);

																							for (int i = 1; i < FunneledPath.Points.Num(); i++)
																								Debug::DrawDebugLine(FunneledPath.Points[i - 1], FunneledPath.Points[i], FLinearColor::Green, 1);

																							// Portal centers
																							FNavigationPath PortalCenterPath;
																							PortalCenterPath.Points.Add(Start);
																							for (FNavOctreePortal Portal : Portals)
																								PortalCenterPath.Points.Add(Portal.Center); 
																							PortalCenterPath.Points.Add(Destination);
																							//PortalCenterPath.DrawDebugSpline(FLinearColor::DPink);

																							for (FNavOctreePortal Portal : Portals)
																							{
																								for (int iCorner = 0; iCorner < 4; iCorner++)
																								{
																									Debug::DrawDebugLine(Portal.Corners[iCorner], Portal.Corners[(iCorner + 1) % 4], FLinearColor::Purple, 3);
																								}
																							}
}
