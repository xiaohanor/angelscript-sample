class UTraversalScenepointComponentVisualizer : UHazeScriptComponentVisualizer
{
	default VisualizedClass = UTraversalScenepointComponent;

	UFUNCTION(BlueprintOverride)
	void VisualizeComponent(UActorComponent Component)
	{
		UTraversalScenepointComponent TraversalScenepoint = Cast<UTraversalScenepointComponent>(Component);
		if (TraversalScenepoint == nullptr)
			return;

		VisualizeScenepoints(Component, TraversalScenepoint);		
	}

	void VisualizeScenepoints(UActorComponent Component, UTraversalScenepointComponent TraversalScenepoint)
	{
		FVector DebugOffset = TraversalScenepoint.Owner.ActorUpVector * 20.0;
		FVector Loc = TraversalScenepoint.WorldLocation + DebugOffset;
		FRotator Rot = TraversalScenepoint.WorldRotation;
		FLinearColor Color = FLinearColor(0.8, 0.4, 0.0);
		DrawDashedLine(Loc, TraversalScenepoint.Owner.ActorLocation + DebugOffset * 4.0, Color, 20.0, 1.0);
		
		SetHitProxy(n"Scenepoint", EVisualizerCursor::Default);
		DrawWireDiamond(Loc, Rot, 20.0, Color, 1.0);
		DrawArrow(Loc, Loc + Rot.Vector() * 50.0, Color, 10.0, 1.0);
		ClearHitProxy();

		
		bool bShowAllArcs = false;
		bool bSelected = Editor::IsComponentSelected(TraversalScenepoint);
#if EDITOR
		ATraversalAreaActorBase Area = Cast<ATraversalAreaActorBase>(Component.Owner);
		if ((Area != nullptr) && Area.bShowAllArcsWhenSelected)
		{
			// Show all arcs unless a traversal point has been selected
			// (if we're selected our arcs will be shown regardless)
			bShowAllArcs = true;
			TArray<UTraversalScenepointComponent> Points;
			Area.GetComponentsByClass(Points);
			for (auto Point : Points)
			{
				if (Editor::IsComponentSelected(Point))
				{
					bShowAllArcs = false;
					break;
				}
			}			
		}
#endif
		VisualizeTraversalPaths(TraversalScenepoint, bSelected, bShowAllArcs);
	}

	void VisualizeTraversalPaths(UTraversalScenepointComponent TraversalScenepoint, bool bSelected, bool bShowAllArcs)
	{	
		// Implement in subclasses
	}

	UFUNCTION(BlueprintOverride)
	bool VisProxyHandleClick(FName HitProxy, FVector ClickOrigin, FVector ClickDirection, FKey Key, EInputEvent Event)
	{
		if (HitProxy == n"Scenepoint")
			Editor::SelectComponent(EditingComponent);	
		return true;	
	}

	FLinearColor GetVisualizationColor(UTraversalScenepointComponent Point, bool bSelected)
	{
		return GetVisualizationColor(Point) * (bSelected ? 1.0 : 0.5);
	}

	FLinearColor GetVisualizationColor(UTraversalScenepointComponent Point)
	{
		if (Point.UsedByMethod.IsValid())
		{
			UTraversalMethod Method = Cast<UTraversalMethod>(Point.UsedByMethod.Get().DefaultObject);			
			if (Method != nullptr)
				return Method.VisualizationColor;
		}
		return FLinearColor::Green;
	}
}


class UArcTraversalScenepointVisualizer : UTraversalScenepointComponentVisualizer
{
	default VisualizedClass = UArcTraversalScenepoint;

	void VisualizeTraversalPaths(UTraversalScenepointComponent TraversalScenepoint, bool bSelected, bool bShowAllArcs) override
	{
		UArcTraversalScenepoint ArcPoint = Cast<UArcTraversalScenepoint>(TraversalScenepoint); 

		FVector DebugOffset = ArcPoint.Owner.ActorUpVector * 20.0;
		FLinearColor ArcColor = GetVisualizationColor(ArcPoint, bSelected);
		float ArcWidth = (bSelected ? 3.0 : 1.0); 
		int nArcPoints = (bSelected ? 60 : 20); 
		for (int i = 0; i < ArcPoint.Destinations.Num(); i++)
		{
			FTraversalArc Arc;
			TArray<FVector> Locs;
			ArcPoint.GetTraversalArc(i, Arc);
			Arc.GetLocations(nArcPoints, Locs);
			if (bSelected || bShowAllArcs)
			{
				for (int j = 1; j < Locs.Num(); j++)
				{
					if (j == Locs.Num() - 1)
						DrawArrow(Locs[j - 1] + DebugOffset, Locs[j] + DebugOffset, ArcColor, ArcWidth);
					else
						DrawLine(Locs[j - 1] + DebugOffset, Locs[j] + DebugOffset, ArcColor, ArcWidth);
				}
			}
		}
	}
}

class UTrajectoryTraversalScenepointVisualizer : UTraversalScenepointComponentVisualizer
{
	default VisualizedClass = UTrajectoryTraversalScenepoint;

	void VisualizeTraversalPaths(UTraversalScenepointComponent TraversalScenepoint, bool bSelected, bool bShowAllArcs) override
	{
		UTrajectoryTraversalScenepoint TrajectoryPoint = Cast<UTrajectoryTraversalScenepoint>(TraversalScenepoint); 

		FVector DebugOffset = TrajectoryPoint.Owner.ActorUpVector * 20.0;
		FLinearColor ArcColor = GetVisualizationColor(TrajectoryPoint, bSelected);
		float ArcWidth = (bSelected ? 3.0 : 1.0); 
		int nArcPoints = (bSelected ? 60 : 20); 
		for (int i = 0; i < TrajectoryPoint.Destinations.Num(); i++)
		{
			FTraversalTrajectory Trajectory;
			TArray<FVector> Locs;
			TrajectoryPoint.GetTraversalTrajectory(i, Trajectory);
			Trajectory.GetLocations(nArcPoints, Locs);
			if (bSelected || bShowAllArcs)
			{
				for (int j = 1; j < Locs.Num(); j++)
				{
					if (j == Locs.Num() - 1)
						DrawArrow(Locs[j - 1] + DebugOffset, Locs[j] + DebugOffset, ArcColor, Thickness = ArcWidth);
					else
						DrawLine(Locs[j - 1] + DebugOffset, Locs[j] + DebugOffset, ArcColor, ArcWidth);
				}
			}
		}
	}
}

class UTeleportTraversalScenepointVisualizer : UTraversalScenepointComponentVisualizer
{
	default VisualizedClass = UTeleportTraversalScenepoint;

	void VisualizeTraversalPaths(UTraversalScenepointComponent TraversalScenepoint, bool bSelected, bool bShowAllArcs) override
	{
		UTeleportTraversalScenepoint TeleportPoint = Cast<UTeleportTraversalScenepoint>(TraversalScenepoint); 
		FVector DebugOffset = TeleportPoint.Owner.ActorUpVector * 20.0;
		FLinearColor Color = GetVisualizationColor(TeleportPoint, bSelected);
		float Width = (bSelected ? 3.0 : 1.0); 
		for (int i = 0; i < TeleportPoint.Destinations.Num(); i++)
		{
			if (bSelected || bShowAllArcs)
				DrawDashedLine(TeleportPoint.WorldLocation, TeleportPoint.GetDestination(i) + DebugOffset, Color, 20.0, Width);
		}
	}
}
