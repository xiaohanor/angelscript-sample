class AIslandSidescrollerTraversalAreaActor : ASidescrollerTraversalAreaActor
{
	default SupportedTraversalClasses.Add(AAIIslandPunchotronSidescroller);
}

struct FSidescrollerTraversalScenepoints
{
	TArray<UTraversalScenepointComponent> Points;
}

UCLASS(Abstract)
class ASidescrollerTraversalAreaActor : ATraversalAreaActor
{	
	UPROPERTY(EditAnywhere)
	float EdgeOffset = 100.0;

	UPROPERTY(EditInstanceOnly)
	ASplineActor FollowSpline;

	// If set to true, the points will not be replaced by a UpdateTraversalAreas call.
	UPROPERTY(EditAnywhere)
	bool bKeepExistingPoints = false;

	void UpdateTraversalAreas() override
	{
	#if EDITOR
		// Find all traversal areas
		TArray<ASidescrollerTraversalAreaActor> AllTraversalAreasRaw = Editor::GetAllEditorWorldActorsOfClass(ASidescrollerTraversalAreaActor);
		TArray<ASidescrollerTraversalAreaActor> AllSidescrollerTraversalAreas;
		TArray<ATraversalAreaActor> AllTraversalAreas;
		for(auto It : AllTraversalAreasRaw)
		{
			AllSidescrollerTraversalAreas.Add(Cast<ASidescrollerTraversalAreaActor>(It));
			AllTraversalAreas.Add(Cast<ATraversalAreaActor>(It));
		}

		// Update points and bounds
		for (ASidescrollerTraversalAreaActor Area : AllSidescrollerTraversalAreas)
		{
			if (Area.bKeepExistingPoints)
			{
				Area.PopulatePointsByMethodMap();
				
				// Clear old destinations
				TArray<UTrajectoryTraversalScenepoint> TraversalPoints;
				Area.GetComponentsByClass(TraversalPoints);
				for (int i = TraversalPoints.Num() - 1; i >= 0; i--)
				{
					TraversalPoints[i].Destinations.Reset();
				}
			}
			else
			{
				// Create traversal points, clear away old ones if exist.
				Area.CreateTraversalPoints();
			}

			TArray<UTraversalScenepointComponent> TraversalPoints;
			Area.GetComponentsByClass(TraversalPoints);
			Area.TraversalBounds = TraversalScenepoint::GetBounds(TraversalPoints);
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

	void PopulatePointsByMethodMap()
	{
		PointsByMethod.Empty();
		TArray<UTraversalScenepointComponent> TraversalPoints;
		GetComponentsByClass(TraversalPoints);
		for (UTraversalScenepointComponent Scenepoint : TraversalPoints)
		{
			// Keep track of which scenepoints are used by which traversal methods
			UClass UsedMethod = Scenepoint.UsedByMethod.Get();
			if (!PointsByMethod.Contains(UsedMethod))
				PointsByMethod.Add(UsedMethod, FTraversalScenepoints()); // note that this empties all lists of scene points created in UpdateTraversalAreas.
			PointsByMethod[UsedMethod].Points.Add(Scenepoint);
		}
	}
	
	void CreateTraversalPoints()
		{
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
					TraversalPoint.WorldLocation = Edge.Center + Pathfinding::GetOutwardsEdgeDirection(Edge, ActorUpVector) * EdgeOffset * -1.0;
					FVector SplineLocation = FollowSpline.Spline.GetClosestSplineWorldLocationToWorldLocation(TraversalPoint.WorldLocation);
					TraversalPoint.WorldLocation = FVector(TraversalPoint.WorldLocation.X, SplineLocation.Y, TraversalPoint.WorldLocation.Z); // Y-coordinate should be read from spline.
					TraversalPoint.WorldRotation = Pathfinding::GetOutwardsEdgeDirection(Edge, ActorUpVector).Rotation();
					for (auto Point : Container.Points)
					{
						if (Point.WorldLocation.PointsAreNear(TraversalPoint.WorldLocation, 10))
						{
							TraversalPoint.DestroyComponent(this);
							break;
						}
					}
					if (!TraversalPoint.IsBeingDestroyed())
						Container.Points.Add(TraversalPoint); //Add to container for immediate use
				}
			}
		}

}
