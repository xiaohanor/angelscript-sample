// Defines how we traverse from one point to another. 
// AIs that traverse must have at least one traversal method specified.
UCLASS(Abstract)
class UTraversalMethod : UObject
{
	TSubclassOf<UTraversalScenepointComponent> ScenepointClass = UTraversalScenepointComponent;

	float MinRange = 200.0;
	float MaxRange = 8000.0;
	float ScenepointInwardsOffset = 0.0;

	FLinearColor VisualizationColor = FLinearColor::White;

	FName MethodName = n"DefaultTraversalMethod";

	bool CanTraverse(UScenepointComponent From, UScenepointComponent To)
	{
		// Implement in subclasses
		return false;
	}

	void AddTraversalPath(UScenepointComponent From, UScenepointComponent To)
	{
		// Implement in subclasses
	}

	bool IsInRange(UScenepointComponent From, UScenepointComponent To)
	{
		if ((From == nullptr) || (To == nullptr))
			return false;

		ATraversalAreaActor Area = Cast<ATraversalAreaActor>(From.Owner);

		float FinalMaxRange = MaxRange;
		if(Area != nullptr && Area.bUseOverrideMaxRange)
			FinalMaxRange = Area.OverrideMaxRange;		
		if (!From.WorldLocation.IsWithinDist(To.WorldLocation, FinalMaxRange))
			return false;

		float FinalMinRange = MinRange;
		if(Area != nullptr && Area.bUseOverrideMinRange)
			FinalMinRange = Area.OverrideMinRange;
		if (From.WorldLocation.IsWithinDist(To.WorldLocation, FinalMinRange))
			return false;
		
		return true;
	}

	bool IsDestinationCandidate(UScenepointComponent Scenepoint)
	{
		// By default we only allow scenepoints of our own preferred class. One must know one's place in society!
		return Scenepoint.IsA(ScenepointClass);
	}
	
	// Override in subclasses as necessary
	bool IsTraversable(FHazeNavmeshEdge Edge)
	{
		// TODO: We need to access Recast's heightfields to be able to check where 
		// the outer edges are walls and where they are edges you can jump off.
		// For now we just use traces.
		FHazeTraceSettings Trace = Trace::InitChannel(ECollisionChannel::WorldGeometry);
		Trace.SetTraceComplex(false);
		Trace.UseLine();
		FVector Up = FVector::UpVector;
		FVector Origin = Edge.Center + Up * 100.0;
		FVector OutwardsDir = Pathfinding::GetOutwardsEdgeDirection(Edge, Up);
		if (OutwardsDir.DotProduct(Edge.Center - Edge.Destination.Center) < 0.0)
			OutwardsDir *= -1.0; // Just in case, should not be needed assuming clockwise edges
		FHitResult Obstruction = Trace.QueryTraceSingle(Origin, Origin + OutwardsDir * 100.0);
		return !Obstruction.bBlockingHit;	
	}
}
