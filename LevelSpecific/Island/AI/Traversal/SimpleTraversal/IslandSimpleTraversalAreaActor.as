// Simple Traversal Area Actor
class AIslandSimpleTraversalAreaActor : ATraversalAreaActorBase
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
	
	UPROPERTY(EditDefaultsOnly)
	TArray<TSubclassOf<AHazeActor>> SupportedTraversalClasses;	

	const FVector DebugOffset = FVector(0.0, 0.0, 10.0);
	const float DebugDuration = 30.0;

	UPROPERTY(VisibleAnywhere)
	TArray<UTraversalMethod> AvailableTraversalMethods;

	UFUNCTION(BlueprintOverride)
	void ConstructionScript()
	{
#if EDITOR
		Billboard.SpriteName = "Traversal";

		TArray<UTraversalMethod> TraversalMethods;
		GetTraversalMethods(TraversalMethods);
		AvailableTraversalMethods = TraversalMethods;		
#endif
	}

	// Add call from a CallInEditor function in a subclass if desired.
	// This will create a point per method, if multiple methods are used.
	// void CreateTraversalPoint()
	// {
	// #if EDITOR
	// 	TArray<UTraversalMethod> TraversalMethods;
	// 	GetTraversalMethods(TraversalMethods); 

	// 	for (UTraversalMethod Method : TraversalMethods)
	// 	{
	// 		if (!Method.ScenepointClass.IsValid())
	// 			continue;
	// 		if (!PointsByMethod.Contains(Method.Class))		
	// 			PointsByMethod.Add(Method.Class, FTraversalScenepoints());
	// 		FTraversalScenepoints& Container = PointsByMethod[Method.Class];
			
	// 		UTraversalScenepointComponent TraversalPoint = Editor::AddInstanceComponentInEditor(this, Method.ScenepointClass, NAME_None);
	// 		if (!ensure(TraversalPoint != nullptr))
	// 			continue;
			
	// 		TraversalPoint.UsedByMethod = Method.Class;
	// 		TraversalPoint.WorldLocation = ActorLocation;
	// 		TraversalPoint.WorldRotation = ActorRotation;
	// 		Container.Points.Add(TraversalPoint); //Add to container for immediate use
	// 	}

	// 	// Update details panel
	// 	Editor::SelectActor(nullptr);
	// 	Editor::SelectActor(this);
	// #endif
	// }
	
	UFUNCTION(CallInEditor)
	void ClearAllTraversalPoints()
	{
	#if EDITOR
		// Remove old traversal points
		TArray<UTraversalScenepointComponent> TraversalPoints;
		GetComponentsByClass(TraversalPoints); // New duplicates of the components get created when constructing, gotta nuke em all! 
		for (int i = TraversalPoints.Num() - 1; i >= 0; i--)
		{
			TraversalPoints[i].DestroyComponent(this);			
		}
		
		// Find new ones for each method
		PointsByMethod.Empty();

		// Update details panel
		Editor::SelectActor(nullptr);
		Editor::SelectActor(this);
	#endif
	}


	// Add call from a CallInEditor function in a subclass if desired.
	void UpdateTraversalAreas()
	{
	#if EDITOR
		// Find all traversal areas
		TArray<AIslandSimpleTraversalAreaActor> AllTraversalAreasRaw = Editor::GetAllEditorWorldActorsOfClass(AIslandSimpleTraversalAreaActor);
		TArray<AIslandSimpleTraversalAreaActor> AllTraversalAreas;
		for(AActor It : AllTraversalAreasRaw)
			AllTraversalAreas.Add(Cast<AIslandSimpleTraversalAreaActor>(It));

		// Update bounds
		for (AIslandSimpleTraversalAreaActor Area : AllTraversalAreas)
		{
			TArray<UTraversalScenepointComponent> TraversalPoints;
			Area.GetComponentsByClass(TraversalPoints);
			Area.TraversalBounds = TraversalScenepoint::GetBounds(TraversalPoints);
		}

		// Update destinations for each area
		for (AIslandSimpleTraversalAreaActor Area : AllTraversalAreas)
		{
			Area.UpdateTraversalDestinations(AllTraversalAreas);
		}

		// Update details panel
		Editor::SelectActor(nullptr);
		Editor::SelectActor(this);
	#endif
	}
	
	// Updates all scenepoint component's destinations in this area.
	void UpdateTraversalDestinations(TArray<AIslandSimpleTraversalAreaActor> TraversalAreas)
	{
		TArray<UTraversalMethod> TraversalMethods;
		GetTraversalMethods(TraversalMethods);
		UpdatePointsByMethod();
		for (UTraversalMethod Method : TraversalMethods)
		{
			// Skip method if there are no points mapped to it
			if (!PointsByMethod.Contains(Method.Class))
				continue;

			TArray<UTraversalScenepointComponent> DestinationCandidates;
			float MaxBoundsRange = TraversalBounds.W + Method.MaxRange;
			for (AIslandSimpleTraversalAreaActor Area : TraversalAreas)
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
					if (OtherPoint.TraversalLaunchType == ETraversalScenepointTrajectoryDirectionType::LaunchingOnly) // No ingoing traversal path for landing points.
						continue;
					if (Method.IsDestinationCandidate(OtherPoint)) // will only match scenepoints with the same scenepoint class specified in its traversal method.
						DestinationCandidates.Add(OtherPoint);
				}	
			}

			// Check for valid destinations for our traversal points
			for (UTraversalScenepointComponent OwnPoint : PointsByMethod[Method.Class].Points)
			{
				if (OwnPoint.TraversalLaunchType == ETraversalScenepointTrajectoryDirectionType::LandingOnly) // No outgoing traversal path for landing points.
					continue;
				if (!OwnPoint.bIsLocked) // Clear unless marked as locked.
					OwnPoint.ClearDestinations();
				for (UTraversalScenepointComponent OtherPoint : DestinationCandidates)
				{
					if (Method.CanTraverse(OwnPoint, OtherPoint))
						Method.AddTraversalPath(OwnPoint, OtherPoint);
				}
			}
		}
	}

	// Update a single component's destinations from this area.
	void UpdateTraversalDestinations(UTraversalScenepointComponent TraversalPoint)
	{
		if (TraversalPoint.TraversalLaunchType == ETraversalScenepointTrajectoryDirectionType::LandingOnly) // No outgoing traversal path for landing points.
			return;
		
		TArray<AIslandSimpleTraversalAreaActor> AllTraversalAreas;
		TArray<AIslandSimpleTraversalAreaActor> AllTraversalAreasRaw = Editor::GetAllEditorWorldActorsOfClass(AIslandSimpleTraversalAreaActor);
		for(AActor It : AllTraversalAreasRaw)
			AllTraversalAreas.Add(Cast<AIslandSimpleTraversalAreaActor>(It));


		TArray<UTraversalMethod> TraversalMethods;
		GetTraversalMethods(TraversalMethods);		
		for (UTraversalMethod Method : TraversalMethods)
		{
			TArray<UTraversalScenepointComponent> DestinationCandidates;
			float MaxBoundsRange = TraversalBounds.W + Method.MaxRange;
			for (AIslandSimpleTraversalAreaActor Area : AllTraversalAreas)
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
					if (OtherPoint.TraversalLaunchType == ETraversalScenepointTrajectoryDirectionType::LaunchingOnly) // No ingoing traversal path for landing points.
						continue;
					if (Method.IsDestinationCandidate(OtherPoint)) // will only match scenepoints with the same scenepoint class specified in its traversal method.
						DestinationCandidates.Add(OtherPoint);
				}
			}

			// Skip method if there are no points mapped to it
			if (TraversalPoint.UsedByMethod.Get() != Method.GetClass())
				continue;


			// Check for valid destinations for our traversal points
			for (UTraversalScenepointComponent OtherPoint : DestinationCandidates)
			{
				if (Method.CanTraverse(TraversalPoint, OtherPoint))
					Method.AddTraversalPath(TraversalPoint, OtherPoint);
			}
		}
	}

	// Recreate PointsByMethod, since the map is cleared in the Editor when the area actor is moved, for instance.
	void UpdatePointsByMethod()
	{
		TArray<UTraversalScenepointComponent> TraversalPoints;
		GetComponentsByClass(TraversalPoints);
		for (UTraversalScenepointComponent Scenepoint : TraversalPoints)
		{			
			// Keep track of which scenepoints are used by which traversal methods
			UClass UsedMethod = Scenepoint.UsedByMethod.Get();
			if (!PointsByMethod.Contains(UsedMethod))
				PointsByMethod.Add(UsedMethod, FTraversalScenepoints());
			PointsByMethod[UsedMethod].Points.AddUnique(Scenepoint);
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
			
			TArray<UTraversalComponentBase> TraversalComps;
			CDO.GetComponentsByClass(UTraversalComponentBase, TraversalComps);
			for (UTraversalComponentBase TraversalComp : TraversalComps)
			{
				if (TraversalComp != nullptr)
					TraversalComp.AddTraversalMethods(MethodClasses);		
			}
		}
		for (TSubclassOf<UTraversalMethod> Method : MethodClasses)
		{
			if (Method.IsValid())
				OutMethods.Add(NewObject(this, Method, bTransient = true));
		}
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
				PointsByMethod.Add(UsedMethod, FTraversalScenepoints());
			PointsByMethod[UsedMethod].Points.Add(Scenepoint);
		}

	}

	UFUNCTION(BlueprintOverride)
	void EndPlay(EEndPlayReason EndPlayReason)
	{
		this.LeaveTeam(TraversalArea::TeamName);
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



}

namespace SimpleTraversalArea
{
	const FName TeamName = n"SimpleTraversalArea";
}

