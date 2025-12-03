// This was intended to use Island-specific TraversalScenepointComponents...
#if EDITOR
class UIslandTraversalScenepointVisualizer : UTrajectoryTraversalScenepointVisualizer
{
	default VisualizedClass = UTrajectoryTraversalScenepoint;

	void VisualizeScenepoints(UActorComponent Component, UTraversalScenepointComponent TraversalScenepoint) override
	{
		FVector DebugOffset = TraversalScenepoint.Owner.ActorUpVector * 20.0;
		FVector Loc = TraversalScenepoint.WorldLocation + DebugOffset;
		FRotator Rot = TraversalScenepoint.WorldRotation;
		
		bool bSelected = Editor::IsComponentSelected(TraversalScenepoint);
		FLinearColor Color = GetVisualizationColor(TraversalScenepoint, bSelected);		
		if (TraversalScenepoint.TraversalLaunchType == ETraversalScenepointTrajectoryDirectionType::LandingOnly)
			Color = FLinearColor(0.7, 0.7, 0.7);
		
		//FLinearColor Color = FLinearColor(0.1, 0.4, 0.0);
		DrawDashedLine(Loc, TraversalScenepoint.Owner.ActorLocation + DebugOffset * 4.0, Color, 20.0, 1.0);
		
		SetHitProxy(n"Scenepoint", EVisualizerCursor::Default);
		DrawWireDiamond(Loc, Rot, 20.0, Color, 1.0);
		DrawArrow(Loc, Loc + Rot.Vector() * 50.0, Color, 10.0, 5.0);
		ClearHitProxy();

		
		bool bShowAllArcs = false;
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
		VisualizeTraversalPaths(TraversalScenepoint, bSelected, bShowAllArcs);
	}

}
#endif
