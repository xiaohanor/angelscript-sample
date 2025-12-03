struct FTraversalScenepoints
{
	TArray<UTraversalScenepointComponent> Points;
}

UCLASS(Abstract)
class ATraversalAreaActorBase : AHazeActor
{
	// MethodClass -> Points map, used ingame. In editor this will become trash after each reconstruction.
	// UClass instead of TSubObjectOf<UTraversalMethod> to since scenepoints shouldn't have a dependency on method.
	UPROPERTY(NotEditable)
	TMap<UClass, FTraversalScenepoints> PointsByMethod;

	// If set to true, this area is just for spawning/passing through. The AI should never stay here.
	UPROPERTY(EditAnywhere)
	bool bTransitArea = false;

	FSphere TraversalBounds;

#if EDITOR
	UPROPERTY(EditInstanceOnly, Category = "Visualization")
	bool bShowAllArcsWhenSelected = true;
#endif

	void UpdateTraversalAreaBounds()
	{
		TArray<ATraversalAreaActorBase> AllTraversalAreas;
		TArray<ATraversalAreaActorBase> AllTraversalAreasRaw = Editor::GetAllEditorWorldActorsOfClass(ATraversalAreaActorBase);
		for(AActor It : AllTraversalAreasRaw)
			AllTraversalAreas.Add(Cast<ATraversalAreaActorBase>(It));

		for (ATraversalAreaActorBase Area : AllTraversalAreas)
		{
			TArray<UTraversalScenepointComponent> TraversalPoints;
			Area.GetComponentsByClass(TraversalPoints);
			Area.TraversalBounds = TraversalScenepoint::GetBounds(TraversalPoints);
		}
	}

	bool HasTraversalPoints(TSubclassOf<UTraversalMethod> Method) const
	{
		if (!PointsByMethod.Contains(Method.Get()))
			return false;
		return (PointsByMethod[Method.Get()].Points.Num() > 0);
	}

	int GetTraversalPoints(TSubclassOf<UTraversalMethod> Method, TArray<UTraversalScenepointComponent>& OutPoints) const
	{
		if (!PointsByMethod.Contains(Method.Get()))
			return 0;
		OutPoints = PointsByMethod[Method.Get()].Points;
		return PointsByMethod[Method.Get()].Points.Num();
	}

	// For use when the TraversalComp has more than one method.
	int GetAllMethodsTraversalPoints(TArray<TSubclassOf<UTraversalMethod>> Methods, TArray<UTraversalScenepointComponent>& OutPoints) const
	{
		for (TSubclassOf<UTraversalMethod> Method : Methods)
		{
			if (!PointsByMethod.Contains(Method.Get()))
				continue;
			OutPoints.Append(PointsByMethod[Method.Get()].Points);			
		}
		return OutPoints.Num();
	}

	UTraversalScenepointComponent GetAnyClosestTraversalPoint(FVector Location) const
	{
		UTraversalScenepointComponent ClosestPoint = nullptr;
		float ClosestDistSqr = BIG_NUMBER;
		for (auto Slot : PointsByMethod)
		{
			for (UTraversalScenepointComponent Point : Slot.Value.Points)
			{
				float DistSqr = Point.WorldLocation.DistSquared(Location);
				if (DistSqr < ClosestDistSqr)
				{
					ClosestPoint = Point;
					ClosestDistSqr = DistSqr;
				}
			}
		}
		return ClosestPoint;
	}

	bool CanUseLandingAt(AHazeActor User, FVector Location, float RangeThreshold = 100.0) const
	{
		UTraversalScenepointComponent Closest = GetAnyClosestTraversalPoint(Location);
		if (!Closest.WorldLocation.IsWithinDist(Location, RangeThreshold))
			return true; // No points near there, we can use this location
		if (Closest.CanUse(User))
			return true;
		return false;	
	}

	// Override in subclasses to handle Component being updated in Editor.
	void UpdateModifiedComponent(UTraversalScenepointComponent Scenepoint) {}
}

UCLASS(Abstract)
class ATraversalAreaActor : ATraversalAreaActorBase
{
	UPROPERTY(DefaultComponent)
	USceneComponent Root;

#if EDITOR
	UPROPERTY(DefaultComponent)
	UEditorBillboardComponent Billboard;
	default Billboard.SpriteName = "Traversal";
	default Billboard.WorldScale3D = FVector(1.0); 
	default Billboard.RelativeLocation = FVector(0.0, 0.0, 200.0);
#endif	

	UPROPERTY(EditAnywhere)
	float TraversalPointMinInterval = 1000.0;

	UPROPERTY(EditAnywhere, Meta = (InlineEditConditionToggle))
	bool bUseOverrideMinRange = false;

	UPROPERTY(EditAnywhere, Meta = (EditCondition = "bUseOverrideMinRange"))
	float OverrideMinRange = -1;

	UPROPERTY(EditAnywhere, Meta = (InlineEditConditionToggle))
	bool bUseOverrideMaxRange = false;

	UPROPERTY(EditAnywhere, Meta = (EditCondition = "bUseOverrideMaxRange"))
	float OverrideMaxRange = -1;

	UPROPERTY(EditDefaultsOnly)
	TArray<TSubclassOf<AHazeActor>> SupportedTraversalClasses;

	// Set as invalid destination by default. Clear with ClearDefaultInvalidDestination function.
	UPROPERTY(EditAnywhere)
	bool bDefaultInvalidDestination;

	private TInstigated<bool> bInvalidDestination;
	const FVector DebugOffset = FVector(0.0, 0.0, 10.0);
	const float DebugDuration = 30.0;

	UFUNCTION(BlueprintOverride)
	void ConstructionScript()
	{
#if EDITOR
		if (bTransitArea)
			Billboard.SpriteName = "Traversal_Transit";
		else
			Billboard.SpriteName = "Traversal";
#endif		
	}

	UFUNCTION(CallInEditor)
	void UpdateTraversalAreas()
	{
	#if EDITOR
		// Find all traversal areas
		TArray<ATraversalAreaActor> AllTraversalAreasRaw = Editor::GetAllEditorWorldActorsOfClass(ATraversalAreaActor);
		TArray<ATraversalAreaActor> AllTraversalAreas;
		for(auto It : AllTraversalAreasRaw)
			AllTraversalAreas.Add(Cast<ATraversalAreaActor>(It));

		// Update points and bounds
		UpdateTraversalAreaBounds();
		for (ATraversalAreaActor Area : AllTraversalAreas)
		{
			Area.BuildTraversalPoints();			
		}

		// Update destinations for each area
		for (ATraversalAreaActor Area : AllTraversalAreas)
		{
			Area.UpdateTraversalDestinations(AllTraversalAreas);
		}

		// Update details panel
		Editor::SelectActor(nullptr);
		Editor::SelectActor(this);
	#endif
	}

	// Creates TraversalPoints. This destroys any existing TraversalPoints, if exist, and creates new ones.
	void BuildTraversalPoints()
	{
		// TODO: this should properly be handled per method as well
		TArray<FHazeNavmeshEdge> OuterEdges;
		FindOuterEdges(ActorLocation, OuterEdges);

		TArray<UTraversalMethod> TraversalMethods;
		GetTraversalMethods(TraversalMethods); 

		TArray<FHazeNavmeshEdge> TraversalEdges;
		FindTraversalEdges(OuterEdges, TraversalPointMinInterval, TraversalEdges, TraversalMethods);

		// Remove old traversal points
		TArray<UTraversalScenepointComponent> TraversalPoints;
		GetComponentsByClass(TraversalPoints); // New duplicates of the components get created when constructing, gotta nuke em all! 
		for (int i = TraversalPoints.Num() - 1; i >= 0; i--)
		{
			TraversalPoints[i].DestroyComponent(this);			
		}

		// Find new ones for each method
		PointsByMethod.Empty();

		for (UTraversalMethod Method : TraversalMethods)
		{
			if (!Method.ScenepointClass.IsValid())
				continue;
			if (!PointsByMethod.Contains(Method.Class))		
				PointsByMethod.Add(Method.Class, FTraversalScenepoints());
			FTraversalScenepoints& Container = PointsByMethod[Method.Class];
			for (FHazeNavmeshEdge Edge : TraversalEdges)
			{
				UTraversalScenepointComponent TraversalPoint = Editor::AddInstanceComponentInEditor(this, Method.ScenepointClass, NAME_None);
				if (!ensure(TraversalPoint != nullptr))
					continue;
				TraversalPoint.UsedByMethod = Method.Class;
				FVector OutwardDir = Pathfinding::GetOutwardsEdgeDirection(Edge, ActorUpVector);
				TraversalPoint.WorldLocation = Edge.Center - OutwardDir * Method.ScenepointInwardsOffset;
				TraversalPoint.WorldRotation = OutwardDir.Rotation();
				Container.Points.Add(TraversalPoint); //Add to container for immediate use
			}
		}
	}

	void UpdateTraversalDestinations(TArray<ATraversalAreaActor> TraversalAreas)
	{
		TArray<UTraversalMethod> TraversalMethods;
		GetTraversalMethods(TraversalMethods); 
		for (UTraversalMethod Method : TraversalMethods)
		{
			if (!PointsByMethod.Contains(Method.Class))
				continue;

			TArray<UTraversalScenepointComponent> DestinationCandidates;
			float MaxBoundsRange = TraversalBounds.W + (bUseOverrideMaxRange ? OverrideMaxRange : Method.MaxRange);
			for (ATraversalAreaActor Area : TraversalAreas)
			{
				if (Area == this)
					continue;
				if (!TraversalBounds.Center.IsWithinDist(Area.TraversalBounds.Center, Area.TraversalBounds.W + MaxBoundsRange))
					continue;
				TArray<UTraversalScenepointComponent> OtherPoints;
				Area.GetComponentsByClass(OtherPoints);
				for (UTraversalScenepointComponent OtherPoint : OtherPoints)
				{
					if (!TraversalBounds.Center.IsWithinDist(OtherPoint.WorldLocation, MaxBoundsRange))
						continue;
					if (Method.IsDestinationCandidate(OtherPoint))
						DestinationCandidates.Add(OtherPoint);
				}	
			}

			// Check for valid destinations for our traversal points
			for (UTraversalScenepointComponent OwnPoint : PointsByMethod[Method.Class].Points)
			{
				for (UTraversalScenepointComponent OtherPoint : DestinationCandidates)
				{
					if (Method.CanTraverse(OwnPoint, OtherPoint))
						Method.AddTraversalPath(OwnPoint, OtherPoint);
				}
			}
		}
	}

	void GetTraversalMethods(TArray<UTraversalMethod>& OutMethods)
	{
		// Check traversal methods from traversal component of all supported classes
		TArray<TSubclassOf<UTraversalMethod>> MethodClasses;
		for (TSubclassOf<AHazeActor> SupportedClass : SupportedTraversalClasses)
		{
			AHazeActor CDO = (SupportedClass.IsValid() ? Cast<AHazeActor>(SupportedClass.Get().GetDefaultObject()) : nullptr);
			if (CDO == nullptr)
				continue;
			UTraversalComponentBase TraversalComp = UTraversalComponentBase::Get(CDO);
			if (TraversalComp != nullptr)
				TraversalComp.AddTraversalMethods(MethodClasses);
		}
		for (TSubclassOf<UTraversalMethod> Method : MethodClasses)
		{
			if (Method.IsValid())
				OutMethods.Add(NewObject(this, Method, bTransient = true));
		}
	}

	void FindTraversalEdges(TArray<FHazeNavmeshEdge> Edges, float MinInterval, TArray<FHazeNavmeshEdge>& TraversalEdges, TArray<UTraversalMethod> TraversalMethods)
	{
		if (Edges.Num() == 0)
			return;
		if (TraversalMethods.Num() == 0)
			return;

		// Sort outer edges into connected pieces 
		TArray<FHazeNavmeshEdge> SortedEdges = Edges;
		for (int iCur = 0; iCur < SortedEdges.Num() - 1; iCur++)
		{
			// Check for edges connected to current edge
			FVector CurLeft = SortedEdges[iCur].Left;
			for (int i = iCur + 1; i < SortedEdges.Num(); i++)
			{
				if (SortedEdges[i].Right.IsWithinDist(CurLeft, 1.0))
				{
					// Found connection, place it next
					SortedEdges.Swap(i, iCur + 1);
					break;
				}
			}
		}

		// Walk outer edges and place edge points at suitable intervals where you can jump off and land
		float WalkDistance = MinInterval;
		FVector PrevLeft = FVector(BIG_NUMBER);
		for (FHazeNavmeshEdge Edge : SortedEdges)
		{
			// If not connected with previous edge, we reset walk distance to 
			// always allow a traversable point here.
			if (!PrevLeft.Equals(Edge.Right, 1.0))
				WalkDistance = MinInterval; 

			float HalfLength = Edge.Length * 0.5;
			UTraversalMethod DefaultMethod = TraversalMethods[0];
			if ((WalkDistance + HalfLength > MinInterval) && DefaultMethod.IsTraversable(Edge))
			{
				// Place new traversable point
				TraversalEdges.Add(Edge);
				WalkDistance = HalfLength;
			}
			else
			{
				// Keep walking, nothing to see here
				WalkDistance += Edge.Length;
			}
			PrevLeft = Edge.Left;
		}
	}

	bool FindOuterEdges(FVector Start, TArray<FHazeNavmeshEdge>& OutEdges)
	{
 		FHazeNavmeshPoly StartPoly = Navigation::FindNearestPoly(Start, 100.0);
		if (!StartPoly.IsValid())
			return false;

		TArray<FHazeNavmeshPoly> Reachable;
		FindReachablePolys(StartPoly, Reachable);
		FindOuterEdges(Reachable, OutEdges);	

		DrawDebugPolys(Reachable);
		return true;
	}

	void FindOuterEdges(TArray<FHazeNavmeshPoly> Polys, TArray<FHazeNavmeshEdge>& OutEdges)
	{
		OutEdges.Reserve(Polys.Num() * 2); // Can be more, but usually fewer
		for (FHazeNavmeshPoly Poly : Polys)
		{
			TArray<FVector> Verts;
			if (Poly.GetVertices(Verts) < 3)
				continue; // 1D-polys need not apply

			// These are the edges leading to other polys, i.e. inner edges
			TArray<FHazeNavmeshEdge> Edges;
			Poly.GetEdges(Edges);

			// Now form edges leading into this poly for each pair of vertices 
			// that are not inner edges 
			FHazeNavmeshEdge OuterEdge;
			OuterEdge.Destination = Poly;
			int nVerts = Verts.Num();
			for (int iLeft = 0; iLeft < nVerts; iLeft++)
			{
				int iRight = (iLeft + 1) % nVerts;
				if (IsAnEdge(Verts[iLeft], Verts[iRight], Edges))
					continue;	
				
				// No inner vertices, form an outer edge
				OuterEdge.Left = Verts[iLeft];
				OuterEdge.Right = Verts[iRight];
				OutEdges.Add(OuterEdge);
			}
		}
	}

	bool IsAnEdge(FVector Left, FVector Right, TArray<FHazeNavmeshEdge> Edges, float Tolerance = 1.0)
	{
		for (FHazeNavmeshEdge Edge : Edges)
		{
			if (Left.Equals(Edge.Left, Tolerance) && Right.Equals(Edge.Right, Tolerance))
				return true;
		}
		return false;
	}

	bool FindOuterVertices(FVector Start, TArray<FVector>& OutVertices)
	{
 		FHazeNavmeshPoly StartPoly = Navigation::FindNearestPoly(Start, 100.0);
		if (!StartPoly.IsValid())
			return false;

		TArray<FHazeNavmeshPoly> Reachable;
		FindReachablePolys(StartPoly, Reachable);

		FindSingleEdgeVertices(Reachable, OutVertices);
		//FindLowCountVertices(Reachable, OutVertices);

		DrawDebugPolys(Reachable);
		//DrawDebugPoly(StartPoly);
		return true;
	}

	void FindReachablePolys(FHazeNavmeshPoly StartPoly, TArray<FHazeNavmeshPoly>& Reachable)
	{
		// Breadth first find all polys reachable from start
		Reachable.Add(StartPoly);
		for (int i = 0; i < Reachable.Num(); i++)
		{
			TArray<FHazeNavmeshPoly> Neighbours;
			Reachable[i].GetNeighbours(Neighbours);
			for (FHazeNavmeshPoly Neighbour : Neighbours)
			{
				Reachable.AddUnique(Neighbour);
			}
		}
	}

	void FindSingleEdgeVertices(TArray<FHazeNavmeshPoly> Reachable, TArray<FVector>& OutVertices)
	{
		for (FHazeNavmeshPoly Poly : Reachable)
		{
			TArray<FVector> Verts;
			if (Poly.GetVertices(Verts) == 0)
				continue;

			// All vertices that belong to two consecutive edges must be inner vertices and should be removed
			// Note that this does not find all inner vertices and also can remove inner corners so could need 
			// some improvements to be generally useful. Good enough for  current case though.
			TArray<FHazeNavmeshEdge> Edges;
			if (Poly.GetEdges(Edges) > 1)
			{
				int nEdges = Edges.Num();
				for (int i = 0; i < nEdges; i++)
				{
					int iPrev = ((i - 1) + nEdges) % nEdges;
					int iNext = (i + 1) % nEdges;
					if (Edges[i].Left.Equals(Edges[iPrev].Right, 1.0) || Edges[i].Left.Equals(Edges[iNext].Right, 1.0))
					{
						for (int j = 0; j < Verts.Num(); j++)
						{
							if (Edges[i].Left.Equals(Verts[j]))
							{
								Verts.RemoveAtSwap(j);
								break;
							}
						}
					}
				}
			}

			// Add all unique verts
			for (FVector Vert : Verts)
			{
				if (!IsVertexCopy(Vert, OutVertices))
					OutVertices.Add(Vert); 
			}
		}
	}

	void FindLowCountVertices(TArray<FHazeNavmeshPoly> Reachable, TArray<FVector>& OutVertices)
	{
		// Count how many almost identical vertices there are
		TArray<FVector> CountedVerts;
		TArray<int> VertexCount;		
		for (FHazeNavmeshPoly Poly : Reachable)
		{
			TArray<FVector> Verts;
			if (Poly.GetVertices(Verts) == 0)
				continue;

			for (FVector Vert : Verts)
			{
				int iCopy = FindVertexCopy(Vert, CountedVerts);
				if (iCopy == -1)
				{
					// New vertex
					CountedVerts.Add(Vert);
					VertexCount.Add(1);
				}
				else
				{
					// Copy
					VertexCount[iCopy]++;
				}
			}	
		}

		// Add all vertices that are only shared by at most two polygons. 
		// Inner corners may be shared by more polys, and we will miss 
		// some others due to acute polygon corners as well.
		for (int i = 0; i < CountedVerts.Num(); i++)
		{
			if (VertexCount[i] < 3)
				OutVertices.Add(CountedVerts[i]);
		}
	}

	bool IsVertexCopy(const FVector& Vert, const TArray<FVector>& Verts, float Tolerance = 1.0)
	{
		return Verts.IsValidIndex(FindVertexCopy(Vert, Verts, Tolerance));
	}

	int FindVertexCopy(const FVector& Vert, const TArray<FVector>& Verts, float Tolerance = 1.0)
	{
		for (int i = 0; i < Verts.Num(); i++)
		{
			if (Vert.Equals(Verts[i], Tolerance))
				return i;
		}
		return -1;
	}

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		UTraversalManager TraversalManager = Cast<UTraversalManager>(this.JoinTeam(TraversalArea::TeamName, UTraversalManager));
		TArray<UTraversalScenepointComponent> TraversalPoints;
		GetComponentsByClass(TraversalPoints);
		for (UTraversalScenepointComponent Scenepoint : TraversalPoints)
		{
			// Since we want to keep track of which area non-traversal scenepoints 
			// are in as well, we cache this in the traversal manager instead of 
			// saving it on each scenepoint.
			TraversalManager.SetScenepointArea(Scenepoint, this);
			
			// Keep track of which scenepoints are used by which traversal methods
			UClass UsedMethod = Scenepoint.UsedByMethod.Get();
			if (!PointsByMethod.Contains(UsedMethod))
				PointsByMethod.Add(UsedMethod, FTraversalScenepoints()); // note that this empties all lists of scene points created in UpdateTraversalAreas.
			PointsByMethod[UsedMethod].Points.Add(Scenepoint);
		}

		if(bDefaultInvalidDestination)
			SetInvalidDestination(this);
	}

	UFUNCTION(BlueprintOverride)
	void EndPlay(EEndPlayReason EndPlayReason)
	{
		this.LeaveTeam(TraversalArea::TeamName);
	}

	void DrawDebugPolys(TArray<FHazeNavmeshPoly> Polys)
	{
		for (auto Poly : Polys)
		{
			DrawDebugPoly(Poly);
		}
	}

	void DrawDebugPoly(FHazeNavmeshPoly Poly)
	{
		TArray<FVector> Verts;
		Poly.GetVertices(Verts);
		FVector PrevVert = Verts.Last();
		for (int i = 0; i < Verts.Num(); i++)
		{
			Debug::DrawDebugLine(PrevVert + DebugOffset, Verts[i] + DebugOffset, FLinearColor::Yellow, 5.0, DebugDuration);
			PrevVert = Verts[i];
		}
	}

	UTraversalScenepointComponent GetClosestTraversalPoint(TSubclassOf<UTraversalMethod> Method, FVector Location) const
	{
		if (!PointsByMethod.Contains(Method.Get()))
			return nullptr;

		UTraversalScenepointComponent ClosestPoint = nullptr;
		float ClosestDistSqr = BIG_NUMBER;
		for (UTraversalScenepointComponent Point : PointsByMethod[Method.Get()].Points)
		{
			if (!Point.HasAnyDestinations())
				continue;

			float DistSqr = Point.WorldLocation.DistSquared(Location);
			if (DistSqr < ClosestDistSqr)
			{
				ClosestPoint = Point;
				ClosestDistSqr = DistSqr;
			}
		}
		return ClosestPoint;
	}	
	
	UTraversalScenepointComponent GetScenepointAtLocation(FVector Location, TSubclassOf<UTraversalScenepointComponent> ScenepointClass, float Radius = 10)
	{
		for(TMapIterator<UClass,FTraversalScenepoints> Slot : PointsByMethod)
		{
			UTraversalMethod Method = Cast<UTraversalMethod>(Slot.Key.GetDefaultObject());
			if(Method.ScenepointClass != ScenepointClass)
				continue;
			for(UTraversalScenepointComponent Point: Slot.Value.Points)
			{
				if(Point.WorldLocation.IsWithinDist(Location, Radius))
					return Point;
			}
		}

		return nullptr;
	}

	UFUNCTION(BlueprintPure)
	bool GetInvalidDestination()
	{
		return bInvalidDestination.Get();
	}

	UFUNCTION()
	void SetInvalidDestination(FInstigator Instigator)
	{
		bInvalidDestination.Apply(true, Instigator);
	}

	UFUNCTION()
	void ClearInvalidDestination(FInstigator Instigator)
	{
		bInvalidDestination.Clear(Instigator);
	}

	UFUNCTION()
	void ClearDefaultInvalidDestination()
	{
		if(bDefaultInvalidDestination)
			bInvalidDestination.Clear(this);
		bDefaultInvalidDestination = false;
	}
}

namespace TraversalArea
{
	const FName TeamName = n"TraversalArea";
}

