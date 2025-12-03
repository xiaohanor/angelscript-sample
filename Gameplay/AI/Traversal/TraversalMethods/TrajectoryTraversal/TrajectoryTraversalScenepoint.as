struct FTrajectoryTraversalScenepointDestination
{
	FTraversalTrajectory LocalTrajectory;
	float Radius;
}

class UTrajectoryTraversalScenepoint : UTraversalScenepointComponent
{
	// Within this radius we're considered at the scenepoint. 
	// Use this as a limit when appearing at a random offset from the point.
	default Radius = 40.0;

	UPROPERTY(NotEditable)
	TArray<FTrajectoryTraversalScenepointDestination> Destinations;

	void AddDestination(FTraversalTrajectory WorldTrajectory, AActor LandArea, float LandRadius)
	{
		FTransform Transform = WorldTransform;
		FTrajectoryTraversalScenepointDestination Destination;
		Destination.LocalTrajectory.LaunchLocation = FVector::ZeroVector;
		Destination.LocalTrajectory.LaunchVelocity = Transform.InverseTransformVectorNoScale(WorldTrajectory.LaunchVelocity);
		Destination.LocalTrajectory.Gravity = Transform.InverseTransformVectorNoScale(WorldTrajectory.Gravity);
		Destination.LocalTrajectory.LandLocation = Transform.InverseTransformPosition(WorldTrajectory.LandLocation);
		Destination.LocalTrajectory.LandArea = LandArea;
		Destination.Radius = LandRadius;
		Destinations.Add(Destination);
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
		return WorldTransform.TransformPosition(Destinations[DestinationIndex].LocalTrajectory.LandLocation);
	}
	
	AActor GetDestinationArea(int DestinationIndex) const override 
	{	
		if (!HasDestination(DestinationIndex))
			return nullptr;	
		return Destinations[DestinationIndex].LocalTrajectory.LandArea;
	}

	bool IsAtDestination(int DestinationIndex, AHazeActor Actor) const override 
	{ 
		if (!HasDestination(DestinationIndex))
			return false; 
		FVector Destination = WorldTransform.TransformPosition(Destinations[DestinationIndex].LocalTrajectory.LandLocation);
		return Actor.ActorLocation.IsWithinDist(Destination, Destinations[DestinationIndex].Radius);
	}

	bool GetTraversalTrajectory(int DestinationIndex, FTraversalTrajectory& OutArc) const
	{
		if (!HasDestination(DestinationIndex))
			return false;
		// We could cache this at beginplay for any non-mobile scenepoint if it ever becomes expensive
		const FTrajectoryTraversalScenepointDestination& Dest = Destinations[DestinationIndex];	
		OutArc = Dest.LocalTrajectory;
		OutArc.LaunchLocation = WorldLocation;
		OutArc.LaunchVelocity = WorldTransform.TransformVectorNoScale(Dest.LocalTrajectory.LaunchVelocity);
		OutArc.Gravity = WorldTransform.TransformVectorNoScale(Dest.LocalTrajectory.Gravity);
		OutArc.LandLocation = WorldTransform.TransformPosition(Dest.LocalTrajectory.LandLocation);
		return true;
	}

	void ClearDestinations() override
	{
		Destinations.Empty();
	}
}
