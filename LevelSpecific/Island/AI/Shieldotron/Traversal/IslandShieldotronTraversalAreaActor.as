class AIslandShieldotronTraversalAreaActor : AIslandSimpleTraversalAreaActor
{
	default SupportedTraversalClasses.Add(AAIIslandShieldotron);
	default SupportedTraversalClasses.Add(AAIIslandPunchotronSidescroller);

	UFUNCTION(CallInEditor)
	void CreateJumpDownTraversalPoint()
	{
	#if EDITOR
		TArray<UTraversalMethod> TraversalMethods;
		GetTraversalMethods(TraversalMethods); 

		for (UTraversalMethod Method : TraversalMethods)
		{
			if (!Method.ScenepointClass.IsValid())
				continue;
			if (Method.MethodName == n"IslandJumpDownTraversalMethod")
			{
				InternalCreateTraversalPoint(Method);
				break;
			}
		}
	#endif
	}

	UFUNCTION(CallInEditor)
	void CreateJumpUpTraversalPoint()
	{
	#if EDITOR
		TArray<UTraversalMethod> TraversalMethods;
		GetTraversalMethods(TraversalMethods); 

		for (UTraversalMethod Method : TraversalMethods)
		{
			if (!Method.ScenepointClass.IsValid())
				continue;
			if (Method.MethodName == n"IslandJumpUpTraversalMethod")
			{
				InternalCreateTraversalPoint(Method);
				break;
			}
		}
	#endif
	}

	protected void InternalCreateTraversalPoint(UTraversalMethod Method)
	{
		#if EDITOR
		if (!PointsByMethod.Contains(Method.Class))		
			PointsByMethod.Add(Method.Class, FTraversalScenepoints());
		FTraversalScenepoints& Container = PointsByMethod[Method.Class];
		
		UTraversalScenepointComponent TraversalPoint = Editor::AddInstanceComponentInEditor(this, Method.ScenepointClass, NAME_None);
		if (!ensure(TraversalPoint != nullptr))
			return;
		
		TraversalPoint.UsedByMethod = Method.Class;
		TraversalPoint.WorldLocation = ActorLocation;
		TraversalPoint.WorldRotation = ActorRotation;
		Container.Points.Add(TraversalPoint); //Add to container for immediate use

		// Update details panel
		Editor::SelectActor(nullptr);
		Editor::SelectActor(this);
		Editor::SelectComponent(TraversalPoint);
	#endif
	}

	// Component being updated in Editor.
	void UpdateModifiedComponent(UTraversalScenepointComponent Scenepoint) override
	{
		UpdateTraversalArc(Scenepoint);
	}

	private void UpdateTraversalArc(UTraversalScenepointComponent Scenepoint)
	{
		if (Scenepoint.bIsLocked)
			return;

		UTrajectoryTraversalScenepoint TraversalScenepoint = Cast<UTrajectoryTraversalScenepoint>(Scenepoint);
		if (TraversalScenepoint == nullptr)
			return;
		
		TraversalScenepoint.Destinations.Empty();

		// Find all traversal areas and update bounds				
		UpdateTraversalAreaBounds();

		UpdateTraversalDestinations(Scenepoint);
	}

	// Updates all outgoing arcs from the scenepoints in this area.
	UFUNCTION(CallInEditor)
	void UpdateTraversalArcs()
	{
	#if EDITOR
		// Find all traversal areas and update bounds				
		UpdateTraversalAreaBounds();

		// Clear old destinations
		TArray<UTrajectoryTraversalScenepoint> TrajectoryTraversalPoints;
		GetComponentsByClass(TrajectoryTraversalPoints);
		for (UTrajectoryTraversalScenepoint TrajectoryTraversalPoint : TrajectoryTraversalPoints)
		{
			if (!TrajectoryTraversalPoint.bIsLocked) // Clear unless marked as locked.
				TrajectoryTraversalPoint.ClearDestinations();
		}

		// Update trajectories to destinations in each area within reach
		TArray<AIslandSimpleTraversalAreaActor> AllTraversalAreas;
		TArray<AIslandSimpleTraversalAreaActor> AllTraversalAreasRaw = Editor::GetAllEditorWorldActorsOfClass(AIslandSimpleTraversalAreaActor);
		for(AActor It : AllTraversalAreasRaw)
			AllTraversalAreas.Add(Cast<AIslandSimpleTraversalAreaActor>(It));

		UpdateTraversalDestinations(AllTraversalAreas);

		// Update details panel
		Editor::SelectActor(nullptr);
		Editor::SelectActor(this);
	#endif
	}

	// Temp function, replaces all TraversalScenepoints with IslandShieldotronTraversalScenepoints
// 	UFUNCTION(CallInEditor)
// 	void ReplaceAllTraversalScenepointsWithOverride()
// 	{
// #if EDITOR
// 		TArray<UTraversalMethod> TraversalMethods;
// 		GetTraversalMethods(TraversalMethods); 

// 		for (UTraversalMethod Method : TraversalMethods)
// 		{
// 			if (!PointsByMethod.Contains(Method.Class))	
// 				continue;
			
// 			FTraversalScenepoints& Container = PointsByMethod[Method.Class];

// 			TArray<UIslandTrajectoryTraversalScenepointComponent> ShieldotronTrajectoryTraversalPoints;
// 			GetComponentsByClass(ShieldotronTrajectoryTraversalPoints);
// 			//if (ShieldotronTrajectoryTraversalPoints.Num() > 0)
// 			//	return; // Already replaced

// 			TArray<UTrajectoryTraversalScenepoint> TrajectoryTraversalPoints;
// 			GetComponentsByClass(TrajectoryTraversalPoints);
// 			for (UTrajectoryTraversalScenepoint TrajectoryTraversalPoint : TrajectoryTraversalPoints)
// 			{
// 				if (TrajectoryTraversalPoint.UsedByMethod != Method.Class)
// 					continue;

// 				// Create a copy
// 				UIslandTrajectoryTraversalScenepointComponent TraversalPoint = Cast<UIslandTrajectoryTraversalScenepointComponent>(Editor::AddInstanceComponentInEditor(this, Method.ScenepointClass, NAME_None));
// 				if (!ensure(TraversalPoint != nullptr))
// 					return;
				
// 				TraversalPoint.UsedByMethod = Method.Class;
// 				TraversalPoint.WorldLocation = TrajectoryTraversalPoint.WorldLocation;
// 				TraversalPoint.WorldRotation = TrajectoryTraversalPoint.WorldRotation;
// 				Container.Points.Add(TraversalPoint); //Add to container for immediate use

				
// 				Container.Points.Remove(TrajectoryTraversalPoint);
				
// 				Editor::DestroyAndRenameInstanceComponentInEditor(TrajectoryTraversalPoint);
// 			}
// 		}
// 		// Update details panel
// 		Editor::SelectActor(nullptr);
// 		Editor::SelectActor(this);
// #endif
//	}

}