// TODO: Move this to c++!
struct FWallClimbingPathNode
{
	FVector Location;
	FVector Normal;

	FWallClimbingPathNode(FVector _Location, FVector _Normal)
	{
		Location = _Location;
		Normal = _Normal;
	}
}

struct FWallClimbingPathfindingNode
{
	// Index to polygon in navmesh
	int iPoly;

	FVector Location;
	float PathCost;
	float HeuristicCost;

	// Index in known nodes list to previous path node
	int iFrom;
}

struct FWallclimbingNavigationNeighbour
{
	int iToPoly;
	int iEdge;
	FVector EdgeRight;
	FVector EdgeLeft;

	FVector GetCenter() const property
	{
		return (EdgeRight + EdgeLeft) * 0.5;
	}
}

struct FWallclimbingNavigationFace
{
	FVector Normal;
	int iAxis; 
	int iSide;
	int iUp;
	float WidestEdge;

	TArray<FVector> Vertices;

	TArray<FWallclimbingNavigationNeighbour> Neighbours;

	FWallclimbingNavigationFace(FVector OpenCenter, FVector OpenExtent, FVector BlockedCenter, FVector BlockedExtent)
	{
		// Normal of face will point away from blocked node. Side and Up axes are set
		// to create a clockwise winding when viewed from above face in normal direction.
		FVector Delta = OpenCenter - BlockedCenter;
		Normal = FVector::ZeroVector;
		if (Math::IsNearlyEqual(OpenExtent.Z + BlockedExtent.Z, Math::Abs(Delta.Z), 1.0))
		{
			// Top/bottom face
			Normal.Z = Math::Sign(Delta.Z); 
			iAxis = 2; iSide = Math::IntegerDivisionTrunc((Math::RoundToInt(Normal.Z) + 1), 2); iUp = (1 - iSide);
		}
		else if (Math::Abs(Delta.X) > Math::Abs(Delta.Y))  
		{
			// Forward/backward face			
			Normal.X = Math::Sign(Delta.X); 
			iAxis = 0; iSide = Math::IntegerDivisionTrunc((Math::RoundToInt(Normal.X) + 1), 2) + 1; iUp = (3 - iSide);
		}
		else 
		{
			// Right/left face
			Normal.Y = Math::Sign(Delta.Y); 
			iAxis = 1; iSide = -(Math::RoundToInt(Normal.Y) - 1); iUp = (2 - iSide);
		}

		// Vert axis value will be constant. Side will be --++ and up -++- to wind clockwise.  
		Vertices.SetNum(4);
		FVector Extent = OpenExtent;
		FVector Origin = OpenCenter;
		float FaceHeightAlongNormal = OpenCenter[iAxis] - OpenExtent[iAxis] * Normal[iAxis]; 
		if (OpenExtent.X > BlockedExtent.X)
		{
			// Blocked node is smaller, place face at edge of blocked
			Extent = BlockedExtent;
			Origin = BlockedCenter;
			FaceHeightAlongNormal = BlockedCenter[iAxis] + BlockedExtent[iAxis] * Normal[iAxis]; 
		}
		for (int i = 0; i < 4; i++)
		{
			Vertices[i][iAxis] = FaceHeightAlongNormal;
			Vertices[i][iSide] = Origin[iSide] + ((Math::IntegerDivisionTrunc(i, 2) * 2) - 1) * Extent[iSide];
			Vertices[i][iUp] = Origin[iUp] + ((Math::IntegerDivisionTrunc(((i + 1) % 4), 2) * 2) - 1) * Extent[iUp];
		}
	}

	bool Merge(FWallclimbingNavigationFace Other)
	{
		// TODO: Improve performance (axis aligned rectangle, so can easily check overlap)
		const float Tolerance = 1.0;
		for (int iOwn = 0; iOwn < Vertices.Num(); iOwn++)
		{
			for (int iOther = 1; iOther < Other.Vertices.Num() + 1; iOther++)
			{
				if (!Vertices[iOwn].IsWithinDist(Other.Vertices[iOther % Other.Vertices.Num()], Tolerance))
					continue;
				
				// Found neighbour sharing vertex. Since all faces are rectangles with clockwise winding, 
				// if our next vertex also matches previous vertex of other face we can merge. 
				int iNext = (iOwn + 1) % Vertices.Num();
				if (Vertices[iNext].IsWithinDist(Other.Vertices[iOther - 1], Tolerance))
				{
					int nOtherVerts = Other.Vertices.Num();
					Vertices[iOwn] = Other.Vertices[(iOther + 1) % nOtherVerts];
					Vertices[iNext] = Other.Vertices[(iOther - 2 + nOtherVerts) % nOtherVerts];
					return true;	
				}
			}
		}
		return false;
	}

	FVector GetCenter() const property 
	{
		FVector LocSum = FVector::ZeroVector;
		for (FVector Vert : Vertices)
		{
			LocSum += Vert;
		}
		return LocSum / float(Math::Max(Vertices.Num(), 1));
	}

	FVector GetEdgeDirection(int iEdge) const
	{
		return Vertices[(iEdge + 1) % Vertices.Num()] - Vertices[iEdge];
	}

	bool GetIntersection(FVector LineStart, FVector LineDir, FVector& OutIntersection) const
	{
		if (Vertices.Num() < 3)
			return false;

		OutIntersection = Math::LinePlaneIntersection(LineStart, LineStart + LineDir, Vertices[0], Normal);	
		if (OutIntersection.ContainsNaN())
			return false;

		if (OutIntersection.Distance(Vertices[0]) > 2000)
			return false;

		FVector FirstEdgeDir = Vertices[1] - Vertices[0];
		float EdgeCrossSign = Math::Sign(Normal.CrossProduct(FirstEdgeDir).DotProduct(OutIntersection - Vertices[0]));
		for (int i = 1; i < Vertices.Num(); i++)
		{
			int iNext = (i + 1) % Vertices.Num();
			float Sign = Math::Sign(Normal.CrossProduct(Vertices[iNext] - Vertices[i]).DotProduct(OutIntersection - Vertices[i]));
			if (EdgeCrossSign != Sign)
			 	return false;
		}
		return true;
	}

	FVector GetClosestLocation(FVector Location) const
	{
		if (Vertices.Num() < 3)
		{
			if (Vertices.Num() == 0)  
				return Location;
			if (Vertices.Num() == 1)
				return Vertices[0];
			return Math::ClosestPointOnLine(Vertices[0], Vertices[1], Location);		
		}

		FVector	PlaneLoc;
		if (GetIntersection(Location, -Normal, PlaneLoc))
			return PlaneLoc;

		// Outside of plane, closest loc is on edge or corner	
		float ClosestDistSqr = BIG_NUMBER;
		FVector ClosestLoc;
		for (int i = 0; i < Vertices.Num(); i++)
		{
			FVector EdgeLoc = Math::ClosestPointOnLine(Vertices[i], Vertices[(i + 1) % Vertices.Num()], PlaneLoc);
			float DistSqr = EdgeLoc.DistSquared(Location);
			if (DistSqr < ClosestDistSqr)
			{
				ClosestDistSqr = DistSqr;
				ClosestLoc = EdgeLoc;
			}
		}
		return ClosestLoc;
	}

	bool IsNeighbour(int iFace) const
	{
		for (FWallclimbingNavigationNeighbour Neighbour : Neighbours)
		{
			if (Neighbour.iToPoly == iFace)
				return true;
		}
		return false;
	}

	int FindNeighbour(int iFace) const
	{
		for (int i = 0; i < Neighbours.Num(); i++)
		{
			if (Neighbours[i].iToPoly == iFace)
				return i;
		}
		return -1;
	}	

	FVector2D Get2DLocation(FVector Loc) const
	{
		return FVector2D(Loc[iSide], Loc[iUp]);
	}

	void DebugDraw(FLinearColor Color, float Duration = 0.0, bool bDrawCornerIndices = false, bool bDrawNeighbours = false, FLinearColor EdgeColor = FLinearColor(0.0, 0.0, 0.0, 0.0)) const
	{
		TArray<int> Indices;
		Indices.Add(0);
		Indices.Add(1);
		Indices.Add(2);
		Indices.Add(2);
		Indices.Add(3);
		Indices.Add(0);
		Debug::DrawDebugMesh(Vertices, Indices, Color * 0.5, Duration);
		for (int i = 0; i < Vertices.Num(); i++)
		{
			Debug::DrawDebugLine(Vertices[i], Vertices[(i + 1) % Vertices.Num()], Color, 5.0, Duration);
			if (bDrawCornerIndices) Debug::DrawDebugString(Vertices[i] + (Center - Vertices[i]) * 0.2, "" + i);
		}
		//Debug::DrawDebugArrow(Center, Center + Normal * 20.0, 5.0, Color, 1.0);
		if (bDrawNeighbours)
		{
			FLinearColor EdgeColour = (EdgeColor.A == 0.0) ? Color : EdgeColor;
			for (FWallclimbingNavigationNeighbour Neighbour : Neighbours)
			{
				FVector EdgeCenter = (Neighbour.EdgeRight + Neighbour.EdgeLeft) * 0.5;	
				FVector Inwards = -Normal.CrossProduct((Neighbour.EdgeLeft - Neighbour.EdgeRight).GetSafeNormal());
				Debug::DrawDebugLine(EdgeCenter, EdgeCenter + Inwards * 10.0, EdgeColour, 2.0, Duration);
				// Debug::DrawDebugLine(EdgeCenter, Center, EdgeColour * 0.5, 0, Duration);
				//if (bDrawCornerIndices) Debug::DrawDebugString(Neighbour.EdgeRight * 0.7 + Neighbour.Center * 0.3, "Right", Duration);
				//if (bDrawCornerIndices) Debug::DrawDebugString(Neighbour.EdgeLeft * 0.7 + Neighbour.Center * 0.3, "Left", Duration);
			}
		}
	}
}

struct FWallclimbingNavigationFaces
{
	TArray<FWallclimbingNavigationFace> Faces;
}

struct FIndices
{
	TArray<int> Indices;
}

struct FEdgeIndices
{
	TArray<int> EdgeIndices;
	TArray<int> FaceIndices;
}

struct FAlignedEdges
{
	TMap<FIntVector, FEdgeIndices> HashedEdges; 
	TArray<FIntVector> Keys;
	TArray<FEdgeIndices> Values;
}

UCLASS(HideCategories = "Collision Physics Cooking Actor Tags HLOD RayTracing Rendering BrushSettings")
class AWallclimbingNavigationVolume : AVolume
{
	default BrushComponent.bCanEverAffectNavigation = false;
	default BrushComponent.CollisionProfileName = n"Trigger"; // n"NoCollision"; EncompassesPoint do not work when there is no collision :/
	default BrushComponent.bGenerateOverlapEvents = false;

	UPROPERTY(BlueprintReadOnly, VisibleAnywhere, Category = "NavigationInternalData")
	TArray<FWallclimbingNavigationFace> NavMesh;

	UPROPERTY(BlueprintReadOnly, VisibleAnywhere, Category = "NavigationInternalData")
	TMap<FIntVector, FIndices> HashedNavMeshPolys;

	TMap<FHazeNavOctreeTileSegmentId, FHazeNavOctreeLeaves> Nodes; 
	TMap<FHazeNavOctreeTileSegmentId, FWallclimbingNavigationFaces> UnmergedFaces; 
	
	TArray<FAlignedEdges> AlignedEdges; 
	TMap<FVector2D, float> BidirectionalCoverage;  

	int iFindNeighboursAlign = 0;
	int iFindNeighboursSlot = 0;

	// Size per slot gives the maximum size of a face, ensuring we don't get too elongated faces..
	const float SlotSize = 500.0;
	const float SlotFactor = 1.0 / SlotSize; 

	bool bEditorDrawNavmesh = false;

	int64 GetNavigationMemoryUsageBytes() const 
	{
		int64 Bytes = 0;

		Bytes += NavMesh.GetAllocatedSize();
		for (auto& Face : NavMesh)
		{
			Bytes += Face.Vertices.GetAllocatedSize();
			Bytes += Face.Neighbours.GetAllocatedSize();
		}

		for (auto& Polys : HashedNavMeshPolys)
		{
			Bytes += 12;
			Bytes += Polys.Value.Indices.GetAllocatedSize();
		}

		return Bytes;
	}

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		Game::GetSingleton(UWallclimbingNavigationVolumeSet).Register(this);

		// Navmesh is saved relative to actor location. Change into world space here when any stremaing offset has been applied.
		FVector WorldOffset = ActorLocation;
		for (FWallclimbingNavigationFace& Poly : NavMesh)
		{
			for (FVector& Vertex : Poly.Vertices)
			{
				Vertex += WorldOffset;
			}
		}
	}

	UFUNCTION(BlueprintOverride)
	void EndPlay(EEndPlayReason EndPlayReason)
	{
		Game::GetSingleton(UWallclimbingNavigationVolumeSet).Unregister(this);
	}

	UFUNCTION(NotBlueprintCallable, CallInEditor, Category = "Navigation")
	void BuildNavmesh()
	{
		FAngelscriptExcludeScopeFromLoopTimeout Scope;
		GetOctreeLeaves();
		if (Nodes.Num() == 0)
			return;

		NavMesh.Empty(NavMesh.Num());
		HashedNavMeshPolys.Empty(HashedNavMeshPolys.Num());
		AlignedEdges.Empty(AlignedEdges.Num()); 
		BidirectionalCoverage.Empty(BidirectionalCoverage.Num());  
		iFindNeighboursAlign = 0;
		iFindNeighboursSlot = 0;

		BuildFaces();
		ApplyModifiers();
		MergeFaces();
		FindNeighbours();

		// Save navmesh offset from our location, so we can place it correctly after world streaming offset has been applied.
		FVector WorldOffset = ActorLocation;
		for (FWallclimbingNavigationFace& Poly : NavMesh)
		{
			for (FVector& Vertex : Poly.Vertices)
			{
				Vertex -= WorldOffset;
			}
		}

		bEditorDrawNavmesh = true;
		EditorDrawNavMesh();
	}

	UFUNCTION(NotBlueprintCallable, CallInEditor, Category = "Navigation")
	void ToggleDrawNavmesh()
	{
		bEditorDrawNavmesh = !bEditorDrawNavmesh;
		if (bEditorDrawNavmesh)
			EditorDrawNavMesh();
		else
			Console::ExecuteConsoleCommand("FlushPersistentDebugLines");
	}

	void GetOctreeLeaves()
	{
		Nodes.Empty();
		float GetLeavesStartTime = Time::PlatformTimeSeconds;
		Navigation::GetNavOctreeLeaves(Bounds.Box, Nodes);		
		if (ShouldDebugPerformance()) Print("Get leaves: " + (Time::PlatformTimeSeconds - GetLeavesStartTime) * 1000, 10);
	}

	void BuildFaces()
	{
		float t = Time::PlatformTimeSeconds;
		UnmergedFaces.Empty(UnmergedFaces.Num());

		for (auto Slot : Nodes)
		{
			FWallclimbingNavigationFaces& TileContent = UnmergedFaces.FindOrAdd(Slot.Key);
			for (FHazeNavOctreeLeaf Node : Slot.Value.Leaves)
			{
				if (Node.bBlocked)
					continue;

				//Find faces where an open node intersects a blocked node
				for (FHazeNavOctreeLeafNeighbour Neighbour : Node.Neighbours)
				{
					FHazeNavOctreeLeaf NeighbourNode = Nodes[Neighbour.TileSegment].Leaves[Neighbour.IndexInTileSegment];	
					if (!NeighbourNode.bBlocked)
						continue;
					TileContent.Faces.Add(FWallclimbingNavigationFace(Node.Center, Node.Extent, NeighbourNode.Center, NeighbourNode.Extent));
				}
			}
		}
		if (ShouldDebugPerformance()) Print("Build faces time: " + (Time::PlatformTimeSeconds - t) * 1000, 100);
	}

	void ApplyModifiers()
	{
		float t = Time::PlatformTimeSeconds;
		TArray<ANavModifierVolume> AllModifiers = Editor::GetAllEditorWorldActorsOfClass(ANavModifierVolume); 
		for (AActor Actor : AllModifiers)
		{
			ANavModifierVolume Modifier = Cast<ANavModifierVolume>(Actor);
			if ((Modifier.AreaClass != UNavArea_Null) &&
				(Modifier.AreaClass != UNavArea_Obstacle))
				continue;

			if (!Modifier.IsBoundsIntersectingActor(this, false))
				continue;

			// Any faces intersecting modifier is culled
			// TODO: Split faces into smaller faces when possible instead
			FName DefaultCollision = Modifier.BrushComponent.CollisionProfileName;
			Modifier.BrushComponent.SetCollisionProfileName(n"OverlapAll");
			for (auto Slot : UnmergedFaces)
			{
				// TODO: Continue if tile does not overlap modifier

				for (int iFace = Slot.Value.Faces.Num() - 1; iFace >= 0; iFace--)
				{
					for (FVector Vert : Slot.Value.Faces[iFace].Vertices)
					{
						if (Modifier.Overlaps(Vert))
						{
							// Found intersecting face
							Slot.Value.Faces.RemoveAtSwap(iFace);
							break;
						}
					}
				}				
			}
			Modifier.BrushComponent.SetCollisionProfileName(DefaultCollision);
		}
		if (ShouldDebugPerformance()) Print("Apply modifiers time: " + (Time::PlatformTimeSeconds - t) * 1000, 100);
	}

	void MergeFaces()
	{
		NavMesh.Reserve(UnmergedFaces.Num() * 100);

		float t = Time::PlatformTimeSeconds;

		for (auto Slot : UnmergedFaces)
		{
			// We only merge faces within each tile
			TArray<FWallclimbingNavigationFace> MergingFaces = Slot.Value.Faces;

			// Sort faces on normal axes, as we can only merge faces with the same normal
			TArray<FIndices> SortedFaces;
			SortFacesByHash(MergingFaces, SortedFaces);

			for (FIndices& AlignedFaces : SortedFaces)
			{
				int PrevNum = 0;
				while (AlignedFaces.Indices.Num() != PrevNum)
				{
					// Allow each face (except the last) a chance to merge with at most one other face
					int iFace = 0;
					int NumLeft = AlignedFaces.Indices.Num();
					PrevNum = NumLeft;
					for (; iFace < NumLeft - 1; iFace++)
					{
						for (int iOther = iFace + 1; iOther < NumLeft; iOther++)
						{
							if (MergingFaces[AlignedFaces.Indices[iFace]].Merge(MergingFaces[AlignedFaces.Indices[iOther]]))
							{
								// Remove merged face from candidates and try to merge a new face 
								// As we only allow each face to merge with at most one other face node before
								// giving another a chance, we should get less elongated faces
								// TODO: Note that this approach may create fishbone patterns of non-merged 
								// faces which can in fact be merged. Fix! 
								// (We should really take all outer vertices in a hash slot and create large 
								// convex hulls instead of keeping the axis aligned squares though)
								AlignedFaces.Indices.RemoveAtSwap(iOther);	
								NumLeft--;
								iFace++;
								break;
							}
						}
					}
				}

				// Done merging this set
				for (int iMerged : AlignedFaces.Indices)
				{
					NavMesh.Add(MergingFaces[iMerged]);
				}
			}
		}
		
		// Shrink navmesh to actual size
		NavMesh.Reserve(NavMesh.Num());

		if (ShouldDebugPerformance()) Print("Merge faces time: " + (Time::PlatformTimeSeconds - t) * 1000, 100);
	}

	void FindNeighbours()
	{
		if ((iFindNeighboursSlot > 0) || (iFindNeighboursAlign > 0))
		{
			for (FWallclimbingNavigationFace& Face : NavMesh)
			{
				Face.Neighbours.Empty();
			}
		}
		iFindNeighboursAlign = 0;
		iFindNeighboursSlot = 0;
		AlignedEdges.Empty();
		BidirectionalCoverage.Empty();		
		
		float t = Time::PlatformTimeSeconds;
		HashEdges(NavMesh, AlignedEdges);
		if (ShouldDebugPerformance()) Print("Hash edges time: " + (Time::PlatformTimeSeconds - t) * 1000, 100);

		//Timer::SetTimer(this, n"FindSomeNeighbours", 0.001);
		FindSomeNeighbours();
	}

	float FindNeighboursTime = 0;
	UFUNCTION()
	void FindSomeNeighbours()
	{
		float t = Time::PlatformTimeSeconds;
		int nCheckedSlots = 0;
		const float Tolerance = 0.1;
		for (int iAlign = iFindNeighboursAlign; iAlign < 3; iAlign++)
		{
			// Neighbouring edges must be within the same align group (or they won't be parallell)
			int iEdgeSide = (iAlign == 1) ? 0 : 1; 
			int iEdgeUp = (iAlign == 2) ? 0 : 2; 
			for (int iSlot = iFindNeighboursSlot; iSlot < AlignedEdges[iAlign].Values.Num(); iSlot++)
			{
				// Neighbours mostly lie within the same hash slot, but we might need to check adjacent slots
				const FEdgeIndices& Values = AlignedEdges[iAlign].Values[iSlot];
				for (int iFaceEdge = 0; iFaceEdge < Values.EdgeIndices.Num(); iFaceEdge++)
				{	
					int iFace = Values.FaceIndices[iFaceEdge];
					int iEdge = Values.EdgeIndices[iFaceEdge];
					FWallclimbingNavigationFace& Face = NavMesh[iFace];
					FVector EdgeLeft = Face.Vertices[iEdge];
					FVector EdgeRight = Face.Vertices[(iEdge + 1) % Face.Vertices.Num()];
					float EdgeMin = Math::Min(EdgeLeft[iAlign], EdgeRight[iAlign]);
					float EdgeMax = Math::Max(EdgeLeft[iAlign], EdgeRight[iAlign]);
					float EdgeLength = EdgeMax - EdgeMin;
					float EdgeCoverage = 0.0;
	
					BidirectionalCoverage.Find(FVector2D(iFace, iEdge), EdgeCoverage);
					if (EdgeCoverage > EdgeLength - Tolerance)
					  	continue; // Already covered

					for (int iHashSlot = 0; iHashSlot < 5; iHashSlot++)
					{
						// Test own hash slot, then adjacent slots before and after along align axis.
						FEdgeIndices OtherIndices;
						if (iHashSlot == 0)
						{
							OtherIndices = Values;
						}
						else 
						{
							// 1 -> -1, 2 -> +1, 3 -> -2, 4 -> +2							
							int Offset = ((iHashSlot & 0x1) * 2 - 1) * Math::IntegerDivisionTrunc((iHashSlot + 1), 2); 
							FIntVector Hash = AlignedEdges[iAlign].Keys[iSlot];
							// There is only a const ref FIntVector operator[], so we can't do Hash[iAlign] += Offset :P 
							Hash.X += Offset * Math::IntegerDivisionTrunc(((iAlign + 2) % 3), 2);
							Hash.Y += Offset * Math::IntegerDivisionTrunc(((iAlign + 1) % 3), 2);
							Hash.Z += Offset * Math::IntegerDivisionTrunc(iAlign, 2);
							if (AlignedEdges[iAlign].HashedEdges.Contains(Hash))
								OtherIndices = AlignedEdges[iAlign].HashedEdges[Hash];	
						}
						 
						for (int iOther = 0; iOther < OtherIndices.EdgeIndices.Num(); iOther++)
						{
							int iOtherFace = OtherIndices.FaceIndices[iOther];
							if (iFace == iOtherFace)
								continue; // Same face

							// Collinear? 
							FWallclimbingNavigationFace& OtherFace = NavMesh[iOtherFace];
							int iOtherEdge = OtherIndices.EdgeIndices[iOther];
							FVector OtherLeft = OtherFace.Vertices[iOtherEdge];
							if (!Math::IsNearlyEqual(EdgeLeft[iEdgeSide], OtherLeft[iEdgeSide], Tolerance) || 
								!Math::IsNearlyEqual(EdgeLeft[iEdgeUp], OtherLeft[iEdgeUp], Tolerance))
								continue; // Nope, not on the same line

							FVector OtherRight = OtherFace.Vertices[(iOtherEdge + 1) % OtherFace.Vertices.Num()];
							float OtherMin = Math::Min(OtherLeft[iAlign], OtherRight[iAlign]);
							float OtherMax = Math::Max(OtherLeft[iAlign], OtherRight[iAlign]);
							if ((EdgeMax < OtherMin + Tolerance) || (EdgeMin > OtherMax - Tolerance))
								continue; // Collinear, but not overlapping segments

							// Do not allow 180 degree normal switching 
							if (Face.Normal.DotProduct(OtherFace.Normal) < -0.999)
								continue; // No balancing on a razors edge!

							// Check if we've already found this face as neighbour when testing other face
							// Note that the above math is cheaper to check on average, so we do this after.
							if (Face.IsNeighbour(iOtherFace))
								continue; // Already found bidirectional neighbour, we can never haev more than one link

							// Overlapping segment, so we've found a neighbour!
							FWallclimbingNavigationNeighbour Neighbour;
							Neighbour.iToPoly = iOtherFace;
							Neighbour.iEdge = iEdge;

							// Neighbours are always bidirectional, set up this face as neighbour to other face
							FWallclimbingNavigationNeighbour OtherNeighbour;
							OtherNeighbour.iToPoly = iFace;
							OtherNeighbour.iEdge = iOtherEdge;

							if (EdgeLeft[iAlign] < EdgeRight[iAlign])
							{
								// Left is low, neighbour left is highest of our left and other right
								Neighbour.EdgeLeft = (EdgeLeft[iAlign] > OtherRight[iAlign]) ? EdgeLeft : OtherRight;
								OtherNeighbour.EdgeRight = Neighbour.EdgeLeft;

								// Neighbour right is lowest of our right and other left, for narrowest edge
								Neighbour.EdgeRight = (EdgeRight[iAlign] < OtherLeft[iAlign]) ? EdgeRight : OtherLeft;
								OtherNeighbour.EdgeLeft = Neighbour.EdgeRight;
							}	
							else
							{
								// Left is high, neighbour left is lowest of our left and other right
								Neighbour.EdgeLeft = (EdgeLeft[iAlign] < OtherRight[iAlign]) ? EdgeLeft : OtherRight;
								OtherNeighbour.EdgeRight = Neighbour.EdgeLeft;

								// Neighbour right is highest of our right and other left, for narrowest edge
								Neighbour.EdgeRight = (EdgeRight[iAlign] > OtherLeft[iAlign]) ? EdgeRight : OtherLeft;
								OtherNeighbour.EdgeLeft = Neighbour.EdgeRight;
							}
							float NeighbourCoverage = Math::Abs(Neighbour.EdgeRight[iAlign] - Neighbour.EdgeLeft[iAlign]);

							Face.Neighbours.Add(Neighbour);
							OtherFace.Neighbours.Add(OtherNeighbour);

							// Early out when we have found all possible neighbours
							// Only 10-15% cheaper than to just skip when a single edge gives full coverage though, if we find neighbours before merging we should revert to that.
							EdgeCoverage += NeighbourCoverage;
							BidirectionalCoverage.Add(FVector2D(iFace, iEdge), EdgeCoverage);
							float OtherCoverage = 0.0;
							BidirectionalCoverage.Find(FVector2D(iOtherFace, iOtherEdge), OtherCoverage);
							BidirectionalCoverage.Add(FVector2D(iOtherFace, iOtherEdge), OtherCoverage + NeighbourCoverage);
							if (EdgeCoverage > EdgeLength - Tolerance)
							 	break; // Found all possible neighbours of edge
						}
						if (EdgeCoverage > EdgeLength - Tolerance)
						 	break; // Early out when we have found all possible neighbours
					}
				} 
				nCheckedSlots++;
				if (nCheckedSlots > 100)
				{
					// Continue later
					FindNeighboursTime += (Time::PlatformTimeSeconds - t);
					iFindNeighboursAlign = iAlign;
					iFindNeighboursSlot = iSlot + 1;
					//Timer::SetTimer(this, n"FindSomeNeighbours", 0.001);
					FindSomeNeighbours();
					return;
				}
			}
			iFindNeighboursSlot = 0;
		}

		// Done building neighbours!
		FindNeighboursTime += (Time::PlatformTimeSeconds - t);
		if (ShouldDebugPerformance()) Print("Find neighbours time: " + (FindNeighboursTime * 1000), 100);

		FinalizeNavMesh();
	}

	void FinalizeNavMesh()
	{
		float t = Time::PlatformTimeSeconds;
		HashNavMesh(NavMesh, HashedNavMeshPolys);
		if (ShouldDebugPerformance()) Print("Hash navmesh: " + ((Time::PlatformTimeSeconds - t) * 1000), 100);

		for (FWallclimbingNavigationFace& Poly : NavMesh)
		{
			Poly.WidestEdge = 0;			
			for (int i = 0; i < Poly.Vertices.Num(); i++)
			{
				float EdgeWidth = (Poly.Vertices[i] - Poly.Vertices[(i + 1) % Poly.Vertices.Num()]).AbsMax;
				if (EdgeWidth > Poly.WidestEdge)
					Poly.WidestEdge = EdgeWidth;	
			}
		}
	}

	bool IsChildOfNeighbour(int iCandidate, TArray<int> AllNeighbours)
	{
		// FVector CandidateCenter = Nodes[iCandidate].Center;
		// for (int iOther : AllNeighbours)
		// {
		// 	if (iOther == iCandidate)
		// 		continue;
		// 	if (Nodes[iOther].Extent.X < Nodes[iCandidate].Extent.X)
		// 		continue; 
		// 	if (FBox(Nodes[iOther].Center - Nodes[iOther].Extent, Nodes[iOther].Center + Nodes[iOther].Extent).IsInside(CandidateCenter))
		// 		return true;
		// }
		return false;
	}

	void SortFacesByHash(TArray<FWallclimbingNavigationFace> FacesToHash, TArray<FIndices>& OutSortedFaces)
	{
		// Hash on center position (with fairly high precision in normal direction)
		// will automatically sort faces by normal direction since they are 
		// squares in a grid. Better performance than just on normal and normal level too.
		TMap<FIntVector, FIndices> HashedFaces;
		FVector WorldOffset = ActorLocation;
		for (int i = 0; i < FacesToHash.Num(); i++)
		{
			FIntVector Hash;
			FVector RelativeCenter = FacesToHash[i].GetCenter() - WorldOffset;
			Hash.X = Math::TruncToInt(RelativeCenter[FacesToHash[i].iAxis] * 0.1); 
			Hash.Y = Math::TruncToInt(RelativeCenter[FacesToHash[i].iSide] * SlotFactor); 
			Hash.Z = Math::TruncToInt(RelativeCenter[FacesToHash[i].iUp] * SlotFactor); 
			HashedFaces.FindOrAdd(Hash).Indices.Add(i);
		}		

		for (auto Slot : HashedFaces)
		{
			OutSortedFaces.Add(Slot.Value);
		}
	}

	void HashEdges(TArray<FWallclimbingNavigationFace> FacesToHash, TArray<FAlignedEdges>& OutAlignedEdges)
	{
		OutAlignedEdges.SetNum(3);
		for (int iFace = 0; iFace < FacesToHash.Num(); iFace++)
		{
			const FWallclimbingNavigationFace& Face = FacesToHash[iFace];
			for (int iEdge = 0; iEdge < Face.Vertices.Num(); iEdge++)
			{
				// Axis aligned, along X -> slot 0, Y -> 1, Z ->2
				FVector Dir = Face.GetEdgeDirection(iEdge);
				int AlignSlot = 0;
				if (!Math::IsNearlyZero(Dir.Y))
					AlignSlot = 1;
				else if (!Math::IsNearlyZero(Dir.Z))
					AlignSlot = 2; 
				FIntVector Hash = GetSlotLocationHash(Face.Vertices[iEdge]);
				OutAlignedEdges[AlignSlot].HashedEdges.FindOrAdd(Hash).FaceIndices.Add(iFace);
				OutAlignedEdges[AlignSlot].HashedEdges[Hash].EdgeIndices.Add(iEdge);
			}
		}
		for (FAlignedEdges& Edges : OutAlignedEdges)
		{
			Edges.Keys.Reserve(Edges.HashedEdges.Num());
			Edges.Values.Reserve(Edges.HashedEdges.Num());
			for (auto Slot : Edges.HashedEdges)
			{
				Edges.Keys.Add(Slot.Key);	
				Edges.Values.Add(Slot.Value);	
			}
		}
	}

	void HashNavMesh(TArray<FWallclimbingNavigationFace> PolysToHash, TMap<FIntVector, FIndices>& HashedPolys)
	{
		HashedPolys.Empty(PolysToHash.Num());
		for (int iFace = 0; iFace < PolysToHash.Num(); iFace++)
		{
			const FWallclimbingNavigationFace& Face = PolysToHash[iFace];
			HashedPolys.FindOrAdd(GetSlotLocationHash(Face.Center)).Indices.Add(iFace);
		}
	}

	FIntVector GetSlotLocationHash(FVector Location) const
	{
		FIntVector Hash;
		Hash.X = Math::TruncToInt(Location.X * SlotFactor); 
		Hash.Y = Math::TruncToInt(Location.Y * SlotFactor);
		Hash.Z = Math::TruncToInt(Location.Z * SlotFactor);
		return Hash;
	}

	int FindPoly(FVector Location, FVector WantedNormal, float UserRadius, float VerticalTolerance, float HorizontalTolerance)
	{
		bool bIgnoreNormal = WantedNormal.IsNearlyZero();
		FVector WantedUp = (bIgnoreNormal ? FVector::UpVector : WantedNormal);
		int nSlotsVertical = 1 + Math::TruncToInt(VerticalTolerance * SlotFactor);
		int nSlotsHorizontal = 1 + Math::TruncToInt(HorizontalTolerance * SlotFactor);
		FIntVector Span = FIntVector(nSlotsHorizontal, nSlotsHorizontal, nSlotsVertical);
		if ((Math::Abs(WantedUp.DotProduct(FVector::RightVector)) > 0.707))
			Span = FIntVector(nSlotsHorizontal, nSlotsVertical, nSlotsHorizontal);
		else if ((Math::Abs(WantedUp.DotProduct(FVector::ForwardVector)) > 0.707))
			Span = FIntVector(nSlotsVertical, nSlotsHorizontal, nSlotsHorizontal);
		FIntVector CenterHash = GetSlotLocationHash(Location);

		float ClosestDistSqr = Math::Square(Math::Max(VerticalTolerance, HorizontalTolerance)) * 2.0;
		int ClosestPoly = -1;
		float HorizontalToleranceSqr = Math::Square(HorizontalTolerance);

		for (int X = CenterHash.X - Span.X; X <= CenterHash.X + Span.X; X++)
		{
			for (int Y = CenterHash.Y - Span.Y; Y <= CenterHash.Y + Span.Y; Y++)
			{
				for (int Z = CenterHash.Z - Span.Z; Z <= CenterHash.Z + Span.Z; Z++)
				{
					FIndices Polys;
					HashedNavMeshPolys.Find(FIntVector(X, Y, Z), Polys);
					for (int iPoly : Polys.Indices)
					{
						const FWallclimbingNavigationFace& Poly = NavMesh[iPoly];
						if (UserRadius > Poly.WidestEdge)
							continue;

						if (!bIgnoreNormal && Poly.Normal.DotProduct(WantedNormal) < 0.5)
							continue;  // Poly facing the wrong way

						float ToPolyVertical = Poly.Normal.DotProduct(Poly.Vertices[0] - Location);
						if (Math::Abs(ToPolyVertical) > VerticalTolerance)
							continue; 

						FVector ClosestPolyLoc = Poly.GetClosestLocation(Location);
						float DistSqr = ClosestPolyLoc.DistSquared(Location);
						if (DistSqr > ClosestDistSqr)
							continue;

						if (HorizontalToleranceSqr < FVector2D(Location[Poly.iSide], Location[Poly.iUp]).DistSquared(FVector2D(ClosestPolyLoc[Poly.iSide], ClosestPolyLoc[Poly.iUp])))
							continue;
						
						ClosestDistSqr = DistSqr;
						ClosestPoly = iPoly;
						// TODO: Start from center and early out if we find poly closer than any polys of other slots
					}
				}
			}
		}
		return ClosestPoly;
	}

	bool FindLocationOnNavmesh(FVector Location, FVector& OutNavmeshLocation, float UserRadius = 0.0, float VerticalTolerance = 200.0, float HorizontalTolerance = 200.0, FVector WantedNormal = FVector::ZeroVector)
	{
		int iPoly = FindPoly(Location, WantedNormal, UserRadius, VerticalTolerance, HorizontalTolerance);
		if (!NavMesh.IsValidIndex(iPoly))
			return false;
		OutNavmeshLocation = NavMesh[iPoly].GetClosestLocation(Location);
		return true;
	}

	bool FindClosestNavmeshPoly(FVector Location, FWallclimbingNavigationFace& OutPoly, float UserRadius = 0.0, float VerticalTolerance = 200.0, float HorizontalTolerance = 200.0, FVector WantedNormal = FVector::ZeroVector)
	{
		int iPoly = FindPoly(Location, WantedNormal, UserRadius, VerticalTolerance, HorizontalTolerance);
		if (!NavMesh.IsValidIndex(iPoly))
			return false;
		OutPoly = NavMesh[iPoly];
		return true;
	}
	
	bool FindPath(FVector Start, FVector StartNormal, FVector Destination, FVector DestinationNormal, float UserRadius, float FindPolyVerticalTolerance, float FindPolyHorizontalTolerance, TArray<FWallClimbingPathNode>& OutPath)
	{
	#if TEST	
		if (bDebugDrawPathfinding)
			Console::ExecuteConsoleCommand("FlushPersistentDebugLines");
	#endif

		int iStartPoly = FindPoly(Start, StartNormal, UserRadius, FindPolyVerticalTolerance, FindPolyHorizontalTolerance);
		if (!NavMesh.IsValidIndex(iStartPoly))
			return false; 
		if (bDebugDrawPathfinding) 
			NavMesh[iStartPoly].DebugDraw(FLinearColor::Green * 0.2);

		int iDestinationPoly = FindPoly(Destination, DestinationNormal, UserRadius, FindPolyVerticalTolerance, FindPolyHorizontalTolerance);
		if (!NavMesh.IsValidIndex(iDestinationPoly))
			return false; 
		if (bDebugDrawPathfinding) 
			NavMesh[iDestinationPoly].DebugDraw(FLinearColor::Yellow * 0.2);

		TArray<FWallClimbingPathfindingNode> RawPath;
		if (!FindPathAStar(Start, iStartPoly, Destination, iDestinationPoly, UserRadius, 5000, RawPath))
			return false;
		TArray<FWallClimbingPathfindingNode> FunneledPath;
		FunnelPath(Start, UserRadius, RawPath, FunneledPath);
		SmoothPath(FunneledPath, OutPath);
		return true;
	}

	private float GetHeuristicCost(FVector Location, FVector Destination)
	{
		return Location.Distance(Destination);
	}

	private bool FindPathAStar(FVector Start, int iStartPoly, FVector Destination, int iDestinationPoly, float UserRadius, int MaxNodes, TArray<FWallClimbingPathfindingNode>& OutPath)
	{
		FWallClimbingPathfindingNode StartNode;
		StartNode.iPoly = iStartPoly;
		StartNode.Location = Start;
		StartNode.PathCost = 0.0;
		StartNode.HeuristicCost = GetHeuristicCost(Start, Destination);
		StartNode.iFrom = -1;

		FWallClimbingPathfindingNode DestinationNode;
		DestinationNode.iPoly = iDestinationPoly;
		DestinationNode.Location = Destination;

		// All nodes found by search
		TArray<FWallClimbingPathfindingNode> KnownNodes;

		// Navmesh poly index to known node index map for efficiency
		TMap<int, int> KnownNodeIndices;
		
		// Indices into known nodes of currently interesting nodes to try searching from
		TArray<int> OpenNodes;

		// Indices into known nodes of already explored nodes 
		TMap<int, int> ClosedNodes;

		KnownNodes.Add(StartNode);
		KnownNodeIndices.Add(StartNode.iPoly, 0);
		OpenNodes.Add(0);

		bool bFoundPath = false;
		while (OpenNodes.Num() > 0)
		{
			// Pop best open node for investigation
			int iCurrentNode = OpenNodes[0];
			FWallClimbingPathfindingNode CurrentNode = KnownNodes[iCurrentNode];
			const FWallclimbingNavigationFace& CurrentPoly = NavMesh[CurrentNode.iPoly];
			OpenNodes.RemoveAt(0);	
// if (bDebugDrawPathfinding) CurrentPoly.DebugDraw(FLinearColor::Green * 0.3, 0.0, false, true);
// if (bDebugDrawPathfinding) Debug::DrawDebugString(CurrentPoly.Center, "" + CurrentNode.iPoly);

// if (CurrentNode.iPoly == 4734)
// {
// 	for (FWallclimbingNavigationNeighbour Neighbour : CurrentPoly.Neighbours)
// 	{
// 		NavMesh[Neighbour.iToPoly].DebugDraw(FLinearColor::Blue * 0.3);
// 		Debug::DrawDebugString(NavMesh[Neighbour.iToPoly].Center, "" + Neighbour.iToPoly);
// 	}	
// }

			// Are we done?
			if (CurrentNode.iPoly == iDestinationPoly)
			{
				DestinationNode.iFrom = CurrentNode.iFrom;	
				bFoundPath = true;
				break;
			}

			// Should we keep trying?
			if (KnownNodes.Num() > MaxNodes)
				break;

			// Explore neighbours
			for (FWallclimbingNavigationNeighbour Neighbour : CurrentPoly.Neighbours)
			{
				FVector NeighbourLoc = NavMesh[Neighbour.iToPoly].Center;

				// TODO: This check fails too easily on a sloped wall, and also would fail on an outward edge where there 
				// might in fact be room to pass. Actual available space should be calculated for neighbour on construction. 
				//if (Neighbour.EdgeLeft.IsWithinDist(Neighbour.EdgeRight, Radius * 2.0)) 
				//	continue; // Edge is to narrow to traverse

				float PathCost = CurrentNode.PathCost + NeighbourLoc.Distance(CurrentNode.Location);				

				int iKnownNode = -1;
				KnownNodeIndices.Find(Neighbour.iToPoly, iKnownNode);
				if (iKnownNode == -1)
				{
					// Previously unknown node, sort into open list
					FWallClimbingPathfindingNode NeighbourNode;
					NeighbourNode.iPoly = Neighbour.iToPoly;
					NeighbourNode.Location = NeighbourLoc;
					NeighbourNode.PathCost = PathCost;
					NeighbourNode.HeuristicCost = GetHeuristicCost(NeighbourLoc, Destination);
					NeighbourNode.iFrom = iCurrentNode;
					KnownNodes.Add(NeighbourNode);
					KnownNodeIndices.Add(NeighbourNode.iPoly, 0);
					InsertSorted(KnownNodes.Num() - 1, KnownNodes, OpenNodes);
				}	
				else if (PathCost < KnownNodes[iKnownNode].PathCost)
				{
					// We found a better way to this already known node, replace it!
					KnownNodes[iKnownNode].PathCost = PathCost; // Heursitic cost will remain the same
					KnownNodes[iKnownNode].iFrom = iCurrentNode;

					// Closed or open?
					if (ClosedNodes.Contains(Neighbour.iToPoly))
					{
						// Closed node, re-open with this brand new improved cost
						ClosedNodes.Remove(Neighbour.iToPoly);
						InsertSorted(iKnownNode, KnownNodes, OpenNodes);
					}
					else
					{
						// Already open, re-sort node with new cost
						ResortLower(iKnownNode, KnownNodes, OpenNodes);
					}
				}			
			}

			// All neighbours have been explored
			ClosedNodes.Add(CurrentNode.iPoly, iCurrentNode);
		}

		if (!bFoundPath)
			return false;

		// Get length of found path
		int iCurFrom = DestinationNode.iFrom;
		int NumNodes = 1;
		while (iCurFrom != -1)
		{
			iCurFrom = KnownNodes[iCurFrom].iFrom;
			NumNodes++;
		} 	
		OutPath.SetNum(NumNodes);

		// Build path from last node in reverse
		OutPath.Last() = DestinationNode;
		for (int i = NumNodes - 2; i >= 0; i--)
		{
			OutPath[i] = KnownNodes[OutPath[i + 1].iFrom];
		}
		return true;
	}

	void InsertSorted(int iNode, const TArray<FWallClimbingPathfindingNode>& KnownNodes, TArray<int>& InOutSortedNodes)
	{
		if (InOutSortedNodes.Num() == 0)
		{
			InOutSortedNodes.Add(iNode);
			return;
		}

		float NewCost = KnownNodes[iNode].PathCost + KnownNodes[iNode].HeuristicCost;
		int iLow = 0; 
		int iHigh = InOutSortedNodes.Num() - 1;

		// Early outs for highest cost (common case) and lowest cost
		const FWallClimbingPathfindingNode LastNode = KnownNodes[InOutSortedNodes[iHigh]];
		if (NewCost >= LastNode.PathCost + LastNode.HeuristicCost)
		{
			InOutSortedNodes.Add(iNode);
			return;
		}
		const FWallClimbingPathfindingNode FirstNode = KnownNodes[InOutSortedNodes[iLow]];
		if (NewCost < FirstNode.PathCost + FirstNode.HeuristicCost)
		{
			InOutSortedNodes.Insert(iNode, 0);
			return;
		}

		// Binary search of interval to insert into
		while (iLow + 1 < iHigh)
		{
			int iMid = Math::IntegerDivisionTrunc((iLow + iHigh), 2);
			const FWallClimbingPathfindingNode MidNode = KnownNodes[InOutSortedNodes[iMid]];
			if (NewCost < MidNode.PathCost + MidNode.HeuristicCost)
				iHigh = iMid;
			else
				iLow = iMid;	
		} 
		InOutSortedNodes.Insert(iNode, iHigh);
	}

	private void ResortLower(int iNode, const TArray<FWallClimbingPathfindingNode>& KnownNodes, TArray<int>& InOutSortedNodes)
	{
		// TODO: Find and shuffle as little as possible of list.
		// Note that we know this node will be sorted in earlier in the list than it's current position,
		// since it's cost has been lowered.
		int iSorted = InOutSortedNodes.FindIndex(iNode);
		InOutSortedNodes.RemoveAt(iSorted);
		InsertSorted(iNode, KnownNodes, InOutSortedNodes);
	}

	const float FunnelPrecision = 0.001;
	private void FunnelPath(FVector Start, float UserRadius, TArray<FWallClimbingPathfindingNode> Path, TArray<FWallClimbingPathfindingNode>& OutPath)
	{
		check(Path.Num() > 0);
		
		// Add starting node
		FWallClimbingPathfindingNode StartNode = Path[0];
		StartNode.Location = Start; 
		OutPath.Add(StartNode);

		// Dummy destination "edge"
		FWallclimbingNavigationNeighbour DestinationDummy;
		DestinationDummy.EdgeLeft = Path.Last().Location;
		DestinationDummy.EdgeRight = Path.Last().Location;

		// We'll likely be visiting nodes multiple times, so find neighbours once beforehand for them all
		TArray<int> Neighbours;
		Neighbours.Reserve(Path.Num() - 1);
		for (int i = 0; i < Path.Num() - 1; i++)
		{
			Neighbours.Add(NavMesh[Path[i].iPoly].FindNeighbour(Path[i + 1].iPoly));
		}

		// Simple funnelling treating wallclimbing path as if unfolded into a 2D path onto funnel poly plane. 
		float DiameterSqr = Math::Square(UserRadius * 2.0);
		int iFunnel = 0;
		while (iFunnel < Path.Num() - 1)
		{
			// Set up funnel reaching from funnel origin to left and right side 
			// of edge leading out of funnel polygon
			const FWallclimbingNavigationFace& FunnelPoly  = NavMesh[Path[iFunnel].iPoly];
			const FWallclimbingNavigationNeighbour& FunnelEdge = FunnelPoly.Neighbours[Neighbours[iFunnel]];
			FVector2D FunnelOrigin = FunnelPoly.Get2DLocation(OutPath.Last().Location);
			FVector2D FunnelEdgeLeft = FunnelPoly.Get2DLocation(FunnelEdge.EdgeLeft); 
			FVector2D FunnelEdgeRight = FunnelPoly.Get2DLocation(FunnelEdge.EdgeRight); 
			FVector2D FunnelOffset = (FunnelEdgeLeft.DistSquared(FunnelEdgeRight) > DiameterSqr) ? (FunnelEdgeRight - FunnelEdgeLeft).GetSafeNormal() * UserRadius : (FunnelEdgeRight - FunnelEdgeLeft) * 0.5;
			FVector2D FunnelLeftDir = FunnelEdgeLeft + FunnelOffset - FunnelOrigin;
			FVector2D FunnelRightDir = FunnelEdgeRight - FunnelOffset - FunnelOrigin;
			int iNarrowLeft = iFunnel;
			int iNarrowRight = iFunnel;

			// Unfold polys along edge leading to next poly
			FVector PrevWorldEdgeRight = FunnelEdge.EdgeRight;
			FVector PrevWorldEdgeLeft = FunnelEdge.EdgeLeft;
			TArray<FVector> UnfoldedEdgesRight;
			UnfoldedEdgesRight.Add(FunnelEdge.EdgeRight);
			TArray<FVector> UnfoldedEdgesLeft;
			UnfoldedEdgesLeft.Add(FunnelEdge.EdgeLeft);

			for (int iTest = iFunnel + 1; iTest < Path.Num(); iTest++)
			{
				const FWallclimbingNavigationFace& Poly = NavMesh[Path[iTest].iPoly];
				FWallclimbingNavigationNeighbour Edge = (iTest < Path.Num() - 1) ? Poly.Neighbours[Neighbours[iTest]] : DestinationDummy;
				FTransform UnfoldingTransform = GetUnfoldingTransform(Poly, PrevWorldEdgeRight, PrevWorldEdgeLeft).Inverse() * 
												GetUnfoldingTransform(FunnelPoly, UnfoldedEdgesRight.Last(), UnfoldedEdgesLeft.Last());
				FVector2D EdgeLeft = FunnelPoly.Get2DLocation(UnfoldingTransform.TransformPosition(Edge.EdgeLeft)); 
				FVector2D EdgeRight = FunnelPoly.Get2DLocation(UnfoldingTransform.TransformPosition(Edge.EdgeRight)); 
				FVector2D Offset = (EdgeLeft.DistSquared(EdgeRight) > DiameterSqr) ? (EdgeRight - EdgeLeft).GetSafeNormal() * UserRadius : (EdgeRight - EdgeLeft) * 0.5;
				FVector2D LeftDir = EdgeLeft + Offset - FunnelOrigin;
				FVector2D RightDir = EdgeRight - Offset - FunnelOrigin;
#if TEST
				DrawDebugFunnelling(Start, iFunnel, iTest, FunnelOrigin, FunnelLeftDir, FunnelRightDir, LeftDir, RightDir, iNarrowLeft, iNarrowRight, FunnelPoly, Poly, UnfoldingTransform, Path, OutPath);
#endif
				// Normally we only need to check side (cross product) for funnelling, 
				// but since we unfold polys we can get edges straight behind funnel which will 
				// cause messy edge cases (badum-pssh), thus we need to check that as well.
				if ((FunnelLeftDir.CrossProduct(RightDir) > FunnelPrecision) || IsStraightBehind(FunnelLeftDir, LeftDir))
				{
				 	// Right edge is to the left of funnel (or left is straight behind left)
					// We turn left at last funnel narrowing point
					const FWallclimbingNavigationFace& LeftPivotPoly = NavMesh[Path[iNarrowLeft].iPoly];
					FVector PivotEdgeLeft = LeftPivotPoly.Neighbours[Neighbours[iNarrowLeft]].EdgeLeft;
					FVector PivotEdgeRight = LeftPivotPoly.Neighbours[Neighbours[iNarrowLeft]].EdgeRight;
					FVector PivotEdgeOffset = (PivotEdgeLeft.DistSquared(PivotEdgeRight) > DiameterSqr) ? (PivotEdgeRight - PivotEdgeLeft).GetSafeNormal() * UserRadius : (PivotEdgeRight - PivotEdgeLeft) * 0.5;
					AddPathTurn(iFunnel, FunnelOrigin, iNarrowLeft, PivotEdgeLeft + PivotEdgeOffset, FunnelLeftDir, UserRadius, UnfoldedEdgesRight, UnfoldedEdgesLeft, Path, Neighbours, OutPath);
					iFunnel = iNarrowLeft + 1;
					break;
				}
				else if (FunnelLeftDir.CrossProduct(LeftDir) < FunnelPrecision)
				{	
					// To the right of left funnel side, narrow funnel
					FunnelLeftDir = LeftDir;
					iNarrowLeft = iTest;
				}

				if ((FunnelRightDir.CrossProduct(LeftDir) < -FunnelPrecision) || IsStraightBehind(FunnelRightDir, RightDir)) 
				{
					// Left edge is to the right of funnel (or right is behind right), 
					// turn right at last funnel narrowing point
					const FWallclimbingNavigationFace& RightPivotPoly = NavMesh[Path[iNarrowRight].iPoly];
					FVector PivotEdgeLeft = RightPivotPoly.Neighbours[Neighbours[iNarrowRight]].EdgeLeft;
					FVector PivotEdgeRight = RightPivotPoly.Neighbours[Neighbours[iNarrowRight]].EdgeRight;
					FVector PivotEdgeOffset = (PivotEdgeLeft.DistSquared(PivotEdgeRight) > DiameterSqr) ? (PivotEdgeRight - PivotEdgeLeft).GetSafeNormal() * UserRadius : (PivotEdgeRight - PivotEdgeLeft) * 0.5;
					AddPathTurn(iFunnel, FunnelOrigin, iNarrowRight, PivotEdgeRight - PivotEdgeOffset, FunnelRightDir, UserRadius, UnfoldedEdgesRight, UnfoldedEdgesLeft, Path, Neighbours, OutPath);
					iFunnel = iNarrowRight + 1;
					break;
				}
				else if (FunnelRightDir.CrossProduct(RightDir) > -FunnelPrecision)
				{
					// To the left of right funnel side, narrow funnel
					FunnelRightDir = RightDir;
					iNarrowRight = iTest;
				}

				// Have we reached destination?
				if (iTest == Path.Num() - 1)
				{
					// Both left and right dir point to unfolded destination
					AddPathTurn(iFunnel, FunnelOrigin, iNarrowRight, Path.Last().Location, RightDir, UserRadius, UnfoldedEdgesRight, UnfoldedEdgesLeft, Path, Neighbours, OutPath);
					iFunnel = Path.Num();
					break;
				}

				// Save previous edge, both in world and unfolded space
				PrevWorldEdgeRight = Edge.EdgeRight;
				PrevWorldEdgeLeft = Edge.EdgeLeft;
				UnfoldedEdgesRight.Add(GetUnfoldedLocation(FunnelPoly, FunnelOrigin + RightDir));
				UnfoldedEdgesLeft.Add(GetUnfoldedLocation(FunnelPoly, FunnelOrigin + LeftDir));
			}
		}

		// Add destination if not already there
		if (!OutPath.Last().Location.Equals(Path.Last().Location))
			OutPath.Add(Path.Last());

#if EDITOR
		//bDebugDrawUnFunneledPath = true;	
		if (bDebugDrawUnFunneledPath)
			DebugDrawUnfunneledPath(Path);		
#endif
	}
	bool bDebugDrawUnFunneledPath = false;	

	bool IsStraightBehind(FVector2D FunnelDir, FVector2D TestDir)
	{
		// In front 180 degrees of funnel. Mostly this will be true, so cheap early out
		float FunnelTestDot = FunnelDir.DotProduct(TestDir);
		if (FunnelTestDot > -FunnelPrecision)
			return false;
		
		// You can be more than 90 degrees behind when traversing from a thin poly but 
		// right/left check is only unreliable when almost straight back, so check against that
		if (Math::Square(FunnelTestDot) > FunnelDir.SizeSquared() * TestDir.SizeSquared() * Math::Square(1.0 - (2.0 * FunnelPrecision)))
			return true;
		return false;
	}

	private FTransform GetUnfoldingTransform(FWallclimbingNavigationFace Poly, FVector EdgeRight, FVector EdgeLeft)
	{
		return FTransform(FQuat::MakeFromZY(Poly.Normal, EdgeRight - EdgeLeft), (EdgeRight + EdgeLeft) * 0.5);
	}

	private void AddPathTurn(int iOrigin, FVector2D UnfoldedOrigin, int iTurn, FVector TurnLocation, FVector2D UnfoldedToTurn, float Radius, TArray<FVector> UnfoldedEdgesRight, TArray<FVector> UnfoldedEdgesLeft, TArray<FWallClimbingPathfindingNode> Path, TArray<int> Neighbours, TArray<FWallClimbingPathfindingNode>& OutPath)
	{
		// Funnelling detected a turn, place a new node at corresponding edge left or right side
		// Since we funnel using a flattened path, we also need to place nodes at any edges where we change poly normal
		const FWallclimbingNavigationFace& BasePoly = NavMesh[Path[iOrigin].iPoly];
		for (int iNode = iOrigin; iNode < iTurn; iNode++)
		{
			const FWallclimbingNavigationFace& PrevPoly = NavMesh[Path[iNode].iPoly];
			const FVector& CurNormal = NavMesh[Path[iNode + 1].iPoly].Normal;
			if (PrevPoly.Normal.DotProduct(CurNormal) > 0.99)	
				continue; // Normal within ~8 degrees, ignore
			
			// Normal changed, get point along edge that is on a straight line to unfolded turn location...
			int iEdge = iNode - iOrigin;
			FVector2D EdgeRight = BasePoly.Get2DLocation(UnfoldedEdgesRight[iEdge]);
			FVector2D EdgeLeft = BasePoly.Get2DLocation(UnfoldedEdgesLeft[iEdge]);
			float EdgeFraction = GetEdgeIntersectionFraction(EdgeLeft, EdgeRight, UnfoldedOrigin, UnfoldedToTurn);

			// ...then place a node at corresponding world location
			const FWallclimbingNavigationNeighbour& EnteringEdge = PrevPoly.Neighbours[Neighbours[iNode]];
			FVector EdgeOffset = (EnteringEdge.EdgeLeft.IsWithinDist(EnteringEdge.EdgeRight, Radius)) ? (EnteringEdge.EdgeRight - EnteringEdge.EdgeLeft) * 0.5 : (EnteringEdge.EdgeRight - EnteringEdge.EdgeLeft).GetSafeNormal() * Radius;
			FVector EdgeWorldLocation = EnteringEdge.EdgeLeft + EdgeOffset + (EnteringEdge.EdgeRight - EnteringEdge.EdgeLeft - EdgeOffset * 2.0) * EdgeFraction; 
			if (!OutPath.Last().Location.Equals(EdgeWorldLocation, 1.0)) // Need to check for duplicates due to unfolding
			{
				FWallClimbingPathfindingNode ChangedNormalIntersection = Path[iNode + 1];
				ChangedNormalIntersection.Location = EdgeWorldLocation;
				OutPath.Add(ChangedNormalIntersection);
			}
		}	

		// Finally place a node at edge corner of funnel turn
		if (!OutPath.Last().Location.Equals(TurnLocation, 1.0))
		{
			int iPolyAfterTurn = (iTurn < Path.Num() - 1) ? iTurn + 1 : iTurn;
			FWallClimbingPathfindingNode FunnelTurn  = Path[iPolyAfterTurn];
			FunnelTurn.Location = TurnLocation;
			OutPath.Add(FunnelTurn);
		}
	}

	private float GetEdgeIntersectionFraction(FVector2D EdgeStart, FVector2D EdgeEnd, FVector2D OtherStart, FVector2D OtherDirection) const
	{
		float Numerator = OtherDirection.CrossProduct(OtherStart - EdgeStart);
		float Denominator = OtherDirection.CrossProduct(EdgeEnd - EdgeStart);
		if (Math::IsNearlyZero(Numerator) || Math::IsNearlyZero(Denominator))
		{
			// We intersect at start or are collinear or parallell (the latter under rare edge cases)
			// Assume intersect at start, since the other results would be arbitrary anyway
			return 0.0;
		}
		return (Numerator / Denominator);
	}

	private FVector GetUnfoldedLocation(FWallclimbingNavigationFace BasePoly, FVector2D UnfoldedLoc2D) const 
	{
		FVector UnfoldedLoc;
		UnfoldedLoc[BasePoly.iSide] = UnfoldedLoc2D.X;
		UnfoldedLoc[BasePoly.iUp] = UnfoldedLoc2D.Y;
		UnfoldedLoc[BasePoly.iAxis] = BasePoly.Vertices[0][BasePoly.iAxis];
		return UnfoldedLoc;
	}

	void DebugDrawUnfunneledPath( TArray<FWallClimbingPathfindingNode> Path)
	{
		for (int i = 0; i < Path.Num(); i++)
		{
			if (i > 0)
				Debug::DrawDebugLine(Path[i-1].Location, Path[i].Location, FLinearColor::Gray, 0);
			Debug::DrawDebugArrow(Path[i].Location, Path[i].Location + NavMesh[Path[i].iPoly].Normal * 20, 5, FLinearColor::Gray, 0);
		}
	}

	void SmoothPath(TArray<FWallClimbingPathfindingNode> Path, TArray<FWallClimbingPathNode>& OutPath)
	{
		if (Path.Num() < 3)
		{
			for (FWallClimbingPathfindingNode Node : Path)
			{
				OutPath.Add(FWallClimbingPathNode(Node.Location, NavMesh[Node.iPoly].Normal));
			}
			return;
		}

		// As path currently can be very jagged with all polys axis aligned, we smooth it out
		// by removing any inwards corners which would be within a reasonable distance from the 
		// straight path between surrounding nodes and adjusting the normal accordingly.
		// TODO: The below is rather crude, and can in worst case smooth path to outside of path polys. Fix!
		const float SmoothingTolerance = 120.0;
		const float NodeDistanceTolerance = 300.0;
		FVector PrevKeptLoc = Path[0].Location;
		OutPath.Add(FWallClimbingPathNode(PrevKeptLoc, NavMesh[Path[0].iPoly].Normal));
		float SkippedWeight = 0.0; 
		FVector SkippedNormalAggregate = FVector::ZeroVector;
		for (int iCur = 1; iCur < Path.Num() - 1; iCur++)
		{
			const FWallClimbingPathfindingNode& CurNode = Path[iCur];
			const FWallClimbingPathfindingNode& PrevNode = Path[iCur - 1];
			FVector CurNormal = NavMesh[CurNode.iPoly].Normal;
			FVector ToPrevDir = (PrevKeptLoc - CurNode.Location).GetSafeNormal();
			float NormalDot = CurNormal.DotProduct(ToPrevDir);
			if (NormalDot > 0.01)
			{
				// Normal is pointing towards previous node, so this is an inwards corner.
				// Skip it if it's not too far from line to the next node and neither previous or next node is very far away	
				FVector NextLoc = Path[iCur + 1].Location;
				if (PrevKeptLoc.IsWithinDist(CurNode.Location, NodeDistanceTolerance) && 
					NextLoc.IsWithinDist(CurNode.Location, NodeDistanceTolerance) && 
					CurNode.Location.IsWithinDist(Math::ProjectPositionOnInfiniteLine(PrevKeptLoc, NextLoc - PrevKeptLoc, CurNode.Location), SmoothingTolerance))
				{
					float CurWeight = PrevNode.Location.Distance(CurNode.Location); 
					SkippedWeight += CurWeight;
					SkippedNormalAggregate += NavMesh[PrevNode.iPoly].Normal * CurWeight;
					continue;
				}
				// Debug::DrawDebugLine(PrevLoc, NextLoc, FLinearColor::Red, 1);
				// FVector LineLoc = Math::ProjectPositionOnInfiniteLine(PrevLoc, NextLoc - PrevLoc, CurNode.Location);
				// Debug::DrawDebugLine(CurNode.Location, LineLoc, FLinearColor::Red, 1);
				// Debug::DrawDebugString(LineLoc, "" + LineLoc.Distance(CurNode.Location));
				// Debug::DrawDebugString((PrevLoc + CurNode.Location) * 0.5, "" + PrevLoc.Distance(CurNode.Location));
				// Debug::DrawDebugString((NextLoc + CurNode.Location) * 0.5, "" + NextLoc.Distance(CurNode.Location));
			}	

			// Found a node to keep. 
			if ((SkippedWeight > 0.0) && !Math::IsNearlyZero(NormalDot))
			{
				// Tweak previous normal to match direction of smoothed path
				float LastWeight = PrevNode.Location.Distance(CurNode.Location);
				SkippedWeight += LastWeight;
				SkippedNormalAggregate += NavMesh[PrevNode.iPoly].Normal * LastWeight;
				OutPath[OutPath.Num() - 1].Normal = SkippedNormalAggregate / SkippedWeight;
			}
			OutPath.Add(FWallClimbingPathNode(CurNode.Location, CurNormal));
			PrevKeptLoc = CurNode.Location;
			SkippedWeight = 0.0;
			SkippedNormalAggregate = FVector::ZeroVector;

		}
		const FWallClimbingPathfindingNode& LastNode = Path.Last();
		OutPath.Add(FWallClimbingPathNode(LastNode.Location, NavMesh[LastNode.iPoly].Normal));

		if (bDebugDrawPathfinding)
			DebugDrawUnsmoothedPath(Path);		
	}

	void DebugDrawUnsmoothedPath(TArray<FWallClimbingPathfindingNode> Path)
	{
		for (int i = 0; i < Path.Num(); i++)
		{
			if (i > 0)
				Debug::DrawDebugLine(Path[i-1].Location, Path[i].Location, FLinearColor::Green, 1);
			Debug::DrawDebugArrow(Path[i].Location, Path[i].Location + NavMesh[Path[i].iPoly].Normal * 50, 10, FLinearColor::LucBlue, 2);
		}
	}

	float DbgDur = 0;
	bool bTestPathfinding = false;
	bool bDebugDrawNavMesh = false;
	bool bDebugDrawPathfinding = false;

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{

#if TEST	
		if (ShouldDebugNavMesh())
			DrawDebugNavMesh();
		if (bTestPathfinding)
			TestPathfinding();
#endif	
	}

	UFUNCTION(DevFunction)
	void ToggleDebugDrawWallclimbingNavmesh()
	{
#if TEST	
		bDebugDrawNavMesh = !bDebugDrawNavMesh;
#endif
	}

	UFUNCTION(DevFunction)
	void ToggleDebugDrawPathfinding()
	{
#if TEST	
		bDebugDrawPathfinding = !bDebugDrawPathfinding;
		if (bDebugDrawPathfinding)
		{
			DbgDur = 1000.0;
		}
		else 
		{
			Console::ExecuteConsoleCommand("FlushPersistentDebugLines");
			DbgDur = 0.0;
		}
#endif
	}

	UFUNCTION(DevFunction)
	void ToggleTestWallClimbingPathfinding()
	{
#if TEST	
		bTestPathfinding = !bTestPathfinding;
#endif
	}

#if TEST	
	void TestPathfinding()
	{
		FVector Start = Game::Mio.ViewLocation + Game::Mio.ViewRotation.Vector() * 400;
		FVector StartNormal = -Game::Mio.ViewRotation.Vector();
		FVector Destination = Game::Zoe.ActorCenterLocation;
		TArray<FWallClimbingPathNode> Path;
		if (FindPath(Start, StartNormal, Destination, FVector::ZeroVector, 40.0, 200.0, 50.0, Path))
		{
			Debug::DrawDebugSphere(Start, 5, 4, FLinearColor::Green, 1, DbgDur);
			Debug::DrawDebugSphere(Destination, 5, 4, FLinearColor::LucBlue, 1, DbgDur);
			Debug::DrawDebugArrow(Path[0].Location, Path[0].Location + Path[0].Normal * 100, 10, FLinearColor::DPink * 0.8, 1, DbgDur);
			for (int i = 1; i < Path.Num(); i++)
			{
				Debug::DrawDebugLine(Path[i - 1].Location, Path[i].Location, FLinearColor::Yellow * 0.8, 2, DbgDur);
				Debug::DrawDebugArrow(Path[i].Location, Path[i].Location + Path[i].Normal * 100, 10, FLinearColor::DPink * 0.8, 1, DbgDur);
				Debug::DrawDebugString(Path[i - 1].Location, "" + (i - 1));
			}
		}
		else
		{
			// No path
			Debug::DrawDebugSphere(Start, 5, 4, FLinearColor::Red, 1, DbgDur * 0.5);
		}
	}
#endif

	bool ShouldDebugPerformance()
	{
#if EDITOR	
		//bHazeEditorOnlyDebugBool = true;	
		if (bHazeEditorOnlyDebugBool)
			return true;
#endif
		return false;
	}

	bool ShouldDebugNavMesh()
	{
		//bDebugDrawNavMesh = true;
		return bDebugDrawNavMesh;
	}

	void EditorDrawNavMesh()
	{
		Console::ExecuteConsoleCommand("FlushPersistentDebugLines");
		FVector WorldOffset = ActorLocation;
		TArray<FWallclimbingNavigationFace> DbgMesh = NavMesh;
		for (FWallclimbingNavigationFace& Face : DbgMesh)
		{
			for (FVector& Vertex : Face.Vertices)
				Vertex += WorldOffset;
		}
		for (FWallclimbingNavigationFace Face : DbgMesh)
		{
			Face.DebugDraw(FLinearColor::Green * 0.3, -1.0, false, true, FLinearColor::Yellow);
		}
	}

	void DrawDebugNavMesh()
	{
		//Debug::DrawDebugCoordinateSystem(ActorLocation + ActorUpVector * (ActorScale3D.Z * 100 + 100), FRotator(), ActorScale3D.X * 100);
		//Debug::DrawDebugCoordinateSystem(Game::Mio.FocusLocation, FRotator(), 40);

		AHazePlayerCharacter ViewPlayer = Game::Zoe;
		if (SceneView::IsFullScreen())
			ViewPlayer = SceneView::FullScreenPlayer;
		FVector ViewLoc = ViewPlayer.ViewLocation;
		FVector ViewDir = ViewPlayer.ViewRotation.Vector();
		float DisplayOffset = 1000.0;
		float DisplayRadius = 8000.0;
		FVector Origin = ViewLoc + ViewDir * DisplayOffset;
		//if (iMergeAlign == SortedFaces.Num())
		{
			int iFocusFace = -1;
			float ClosestDistSqr = BIG_NUMBER;
			for (int iFace = 0; iFace < NavMesh.Num(); iFace++)
			{
				FVector Intersection;
				if (NavMesh[iFace].Center.IsWithinDist(Origin, DisplayRadius) && NavMesh[iFace].GetIntersection(ViewLoc, ViewDir, Intersection))
				{
					float DistSqr = ViewLoc.DistSquared(Intersection);
					if (DistSqr < ClosestDistSqr)
					{
						ClosestDistSqr = DistSqr;
						iFocusFace = iFace;
					}
				} 
			}

			for (int iFace = 0; iFace < NavMesh.Num(); iFace++)
			{
				const FWallclimbingNavigationFace& Face = NavMesh[iFace];
				//if (Face.Center.IsWithinDist(Origin, DisplayRadius))
					//Face.DebugDraw(FLinearColor::Green * 0.3, 0.0, (Face.Center.Y == MergedFaces[1443].Center.Y), (Face.Center.Y == MergedFaces[1443].Center.Y));
					//Face.DebugDraw(FLinearColor::Green * 0.3, 0.0, iFace == iFocusFace, iFace == iFocusFace);
					Face.DebugDraw(FLinearColor::Green * 0.3, 0.0, iFace == iFocusFace, true);
				//if (Face.Center.Z == MergedFaces[5934].Center.Z) Debug::DrawDebugString(Face.Center, "" + iFace);
				if (iFace == iFocusFace)
				{
					Debug::DrawDebugString(Face.Center, "" + iFace);
					for (FWallclimbingNavigationNeighbour NeighbourLink : Face.Neighbours)
					{
						const FWallclimbingNavigationFace& NeighbourFace = NavMesh[NeighbourLink.iToPoly];
						FVector EdgeCenter = (NeighbourLink.EdgeRight + NeighbourLink.EdgeLeft) * 0.5;	
						FVector Inwards = NeighbourFace.Normal.CrossProduct((NeighbourLink.EdgeRight - NeighbourLink.EdgeLeft).GetSafeNormal());
						Debug::DrawDebugLine(EdgeCenter, EdgeCenter + Inwards * 10.0, FLinearColor::Green * 0.5, 2.0);
						Debug::DrawDebugLine(EdgeCenter, NeighbourFace.Center, FLinearColor::Gray, Thickness = 0);
					}
				}
			}

			//if (MergedFaces.IsValidIndex(iFocusFace)) Debug::DrawDebugCoordinateSystem(MergedFaces[iFocusFace].Center + FVector(200,0,10), FRotator(), 100);
		}
		//else
		{
			// Merging
			// for (FIndices SortedSLot : SortedFaces)
			// {
			// 	for (int i : SortedSLot.Indices)
			// 	{
			// 		FWallclimbingNavigationFace Face = MergingFaces[i];
			// 		if (Face.Center.IsWithinDist(Origin, DisplayRadius))
			// 			Face.DebugDraw(FLinearColor::Green * 0.3);
			// 	}
			// }
		}

		// FVector NodeDebugOrigin = ViewLoc + ViewDir * 400.0;
		// for (int iNode = 0; iNode < Nodes.Num(); iNode++)	
		// {
		// 	auto Node = Nodes[iNode];
		// 	FBox NodeBox(Node.Center - Node.Extent, Node.Center + Node.Extent);
		// 	//if (Node.Center.IsWithinDist(NodeDebugOrigin, 100.0) || NodeBox.IsInside(NodeDebugOrigin))
		// 	if (NodeBox.IsInside(NodeDebugOrigin))
		// 	{
		// 		Debug::DrawDebugString(Node.Center, "" + iNode);
		// 		Debug::DrawDebugSolidBox(Node.Center, Node.Extent * 0.9, FRotator(), (Node.bBlocked ? FLinearColor::Blue : FLinearColor::White) * 0.3);
		// 	}
		// }

		// FVector FindPolyOrigin = Game::Mio.ViewLocation + Game::Mio.ViewRotation.Vector() * 200;
		// int iPoly = FindPoly(FindPolyOrigin, -Game::Mio.ViewRotation.Vector(), 40, 400, 100); 
		// Debug::DrawDebugSphere(FindPolyOrigin, 2, 4, FLinearColor::Yellow * 0.5);
		// if (NavMesh.IsValidIndex(iPoly))
		// {
		// 	NavMesh[iPoly].DebugDraw(FLinearColor::Green * 0.5);
		// 	FVector Closest = NavMesh[iPoly].GetClosestLocation(Origin);
		// 	Debug::DrawDebugLine(FindPolyOrigin, Closest, FLinearColor::Yellow * 0.5);
		// }
	}

	void DrawDebugFunnelling(FVector Start, int iFunnel, int iTest, FVector2D FunnelOrigin, FVector2D FunnelLeftDir, FVector2D FunnelRightDir, FVector2D LeftDir, FVector2D RightDir, int iNarrowLeft, int iNarrowRight, FWallclimbingNavigationFace FunnelPoly, FWallclimbingNavigationFace Poly, FTransform UnfoldingTransform, TArray<FWallClimbingPathfindingNode> RawPath, TArray<FWallClimbingPathfindingNode> ResultPath)
	{
		//bDebugDrawPathfinding = true;
		if (!bDebugDrawPathfinding)
			return;

		if (iFunnel == -1)
		{
			FVector Origin = ResultPath.Last().Location;
			Origin[FunnelPoly.iAxis] = FunnelPoly.Center[FunnelPoly.iAxis];
			FVector FunnelOffset = FunnelPoly.Normal * 10.0 + FVector(0,0,0);
			FVector FullOffset = FunnelOffset + FunnelPoly.Normal * (((iTest - iFunnel) * 2) + 2.0);  
			FLinearColor LeftColor = FLinearColor(1,0.3,0); // Orange
			FLinearColor RightColor = FLinearColor(1,0.2,0.4); // Pink
			int iDbg = 1;
			if (iDbg == 0 || iDbg + iFunnel == iTest)
			{
				Debug::DrawDebugLine(Origin + FullOffset, GetUnfoldedLocation(FunnelPoly, FunnelOrigin + FunnelLeftDir) + FullOffset, LeftColor, 1.8, DbgDur);
				Debug::DrawDebugLine(Origin + FullOffset, GetUnfoldedLocation(FunnelPoly, FunnelOrigin + FunnelRightDir) + FullOffset, RightColor, 1.8, DbgDur);
			}
			FVector LeftTest = GetUnfoldedLocation(FunnelPoly, FunnelOrigin + LeftDir);
			FVector RightTest = GetUnfoldedLocation(FunnelPoly, FunnelOrigin + RightDir);
			if ((FunnelLeftDir.DotProduct(LeftDir) < -FunnelPrecision) || (FunnelRightDir.DotProduct(RightDir) < -FunnelPrecision) || (FunnelLeftDir.CrossProduct(RightDir) > FunnelPrecision) || (FunnelRightDir.CrossProduct(LeftDir) < -FunnelPrecision)) 
				{ LeftColor = RightColor = FLinearColor(1,0,0); Debug::DrawDebugString((LeftTest + RightTest) * 0.5 + FunnelOffset, "Next: " + ((FunnelLeftDir.CrossProduct(RightDir) > FunnelPrecision) ? iNarrowLeft + 1 : iNarrowRight + 1));}
			else if (iTest == RawPath.Num() - 1)
				LeftColor = RightColor = FLinearColor(0.1,0.1,1);
			if (iDbg == 0 || iDbg + iFunnel == iTest)
			{
				Debug::DrawDebugLine(Origin + FullOffset, LeftTest + FullOffset, LeftColor, 0.5, DbgDur);
				Debug::DrawDebugLine(Origin + FullOffset, RightTest + FullOffset, RightColor, 0.5, DbgDur);
				Debug::DrawDebugSphere(LeftTest + FullOffset, 3, 4, LeftColor, 1, DbgDur);
				Debug::DrawDebugSphere(RightTest + FullOffset, 3, 4, RightColor, 1, DbgDur);
			}
			FWallclimbingNavigationFace UnfoldedFace;
			UnfoldedFace.Normal = FunnelPoly.Normal;
			for (int j = 0; j < Poly.Vertices.Num(); j++)
			{
				UnfoldedFace.Vertices.Add(GetUnfoldedLocation(FunnelPoly, FunnelPoly.Get2DLocation(UnfoldingTransform.TransformPosition(Poly.Vertices[j]))) + FunnelOffset);
			}
			UnfoldedFace.DebugDraw(FLinearColor::LucBlue * 0.5);
			FWallclimbingNavigationFace OffsetFunnelPoly = FunnelPoly;
			for (int j = 0; j < Poly.Vertices.Num(); j++)
			{
				OffsetFunnelPoly.Vertices[j] += FunnelOffset;
			}
			OffsetFunnelPoly.DebugDraw(FLinearColor::LucBlue * 0.5);
			// Debug::DrawDebugLine(FunnelEdge.EdgeRight + FunnelOffset, FunnelEdge.EdgeLeft + FunnelOffset, FLinearColor::Black, 5, DbgDur);
			// Debug::DrawDebugCoordinateSystem(UnfoldingTransform.Location + FunnelOffset, UnfoldingTransform.Rotator(), 50);	// Unfolding transform
			// Debug::DrawDebugCoordinateSystem(GetUnfoldingTransform(Poly, PrevWorldEdgeRight, PrevWorldEdgeLeft).Location  + FunnelOffset + Poly.Normal * 50, GetUnfoldingTransform(Poly, PrevWorldEdgeRight, PrevWorldEdgeLeft).Rotator(), 20); // Uninversed local transform 
		}
		// Draw this once only
		if (iTest == 1 || RawPath.Num() == 1)
		{
			Debug::DrawDebugSphere(Start, 5, 4, FLinearColor::Green, 1, DbgDur);
			Debug::DrawDebugSphere(RawPath.Last().Location, 5, 4, FLinearColor::LucBlue, 1, DbgDur);
			NavMesh[RawPath[0].iPoly].DebugDraw(FLinearColor::Green * 0.2, DbgDur);
			for (int i = 1; i < RawPath.Num(); i++)
			{
				//Debug::DrawDebugLine(Path[i - 1].Location, Path[i].Location, FLinearColor::White * 0.5, 1, DbgDur);
				NavMesh[RawPath[i].iPoly].DebugDraw(FLinearColor::Green * 0.2, DbgDur);
			}
		}
	}
}

