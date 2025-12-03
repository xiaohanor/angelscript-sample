struct FTeleportTraversalScenepointDestination
{
	FVector Location;
	AActor Area;
	float Radius;
}

class UTeleportTraversalScenepoint : UTraversalScenepointComponent
{
	// Within this radius we're considered at the scenepoint. 
	// Use this as a limit when appearing at a random offset from the point.
	default Radius = 40.0;

	UPROPERTY(NotEditable)
	TArray<FTeleportTraversalScenepointDestination> Destinations;

	void AddDestination(FVector WorldDestination, AActor DestinationArea, float DestinationRadius)
	{
		FTeleportTraversalScenepointDestination Dest;
		Dest.Location = WorldTransform.InverseTransformPosition(WorldDestination);
		Dest.Area = DestinationArea;
		Dest.Radius = DestinationRadius;
		Destinations.Add(Dest);
	}

	bool HasDestination(int DestinationIndex) const override 
	{ 
		return Destinations.IsValidIndex(DestinationIndex); 
	}

	int GetDestinationCount() const override 
	{ 
		return Destinations.Num();	
	}

	FVector GetDestination(int DestinationIndex) const override 
	{ 
		if (!HasDestination(DestinationIndex))
			return WorldLocation; 
		return WorldTransform.TransformPosition(Destinations[DestinationIndex].Location);
	}
	
	AActor GetDestinationArea(int DestinationIndex) const override 
	{	
		if (!HasDestination(DestinationIndex))
			return nullptr;	
		return Destinations[DestinationIndex].Area;
	}

	bool IsAtDestination(int DestinationIndex, AHazeActor Actor) const override 
	{ 
		if (!HasDestination(DestinationIndex))
			return false; 
		FVector Destination = WorldTransform.TransformPosition(Destinations[DestinationIndex].Location);
		return Actor.ActorLocation.IsWithinDist(Destination, Destinations[DestinationIndex].Radius);
	}

	bool CanUseDestination(int DestinationIndex, AHazeActor User) const override
	{ 
		if (!HasDestination(DestinationIndex))
			return false; 
		// TODO: Hack to check which scenepoint we have as our destination.
		ATraversalAreaActor TraversalArea = Cast<ATraversalAreaActor>(Destinations[DestinationIndex].Area);
		UScenepointComponent DestinationScenepoint = TraversalArea.GetScenepointAtLocation(Destinations[DestinationIndex].Location, UTeleportTraversalScenepoint);
		if(DestinationScenepoint == nullptr)
			return false;
		if(!DestinationScenepoint.CanUse(User))
			return false;

		return true; 
	}

	void ClearDestinations() override
	{
		Destinations.Empty();
	}
}
