struct FArcTraversalScenepointDestination
{
	FTraversalArc LocalArc;
	float LandRadius;
}

class UArcTraversalScenepoint : UTraversalScenepointComponent
{
	default Radius = 40.0;

	// Angle at which we take off from/land at point
	UPROPERTY(EditAnywhere)
	float TraversalPitch = 90.0;

	UPROPERTY(EditAnywhere)
	float LaunchTangentLength = 500.0;

	UPROPERTY(EditAnywhere)
	float LandTangentLength = 500.0;

	UPROPERTY(NotEditable)
	TArray<FArcTraversalScenepointDestination> Destinations;

	void AddDestination(FTraversalArc WorldArc, AActor LandArea, float LandRadius)
	{
		FTransform Transform = WorldTransform;
		FArcTraversalScenepointDestination Destination;
		Destination.LocalArc.LaunchLocation = FVector::ZeroVector;
		Destination.LocalArc.LaunchTangent = Transform.InverseTransformVectorNoScale(WorldArc.LaunchTangent);
		Destination.LocalArc.LandLocation = Transform.InverseTransformPosition(WorldArc.LandLocation);
		Destination.LocalArc.LandTangent = Transform.InverseTransformVectorNoScale(WorldArc.LandTangent);
		Destination.LocalArc.LandArea = LandArea;
		Destination.LandRadius = LandRadius;
		Destinations.Add(Destination);
	}

	FVector GetDestination(int DestinationIndex) const override
	{
		if (!HasDestination(DestinationIndex))
			return WorldLocation;
		return WorldTransform.TransformPosition(Destinations[DestinationIndex].LocalArc.LandLocation);
	}

	bool HasDestination(int DestinationIndex) const override
	{
		return Destinations.IsValidIndex(DestinationIndex);
	}

	int GetDestinationCount() const override
	{
		return Destinations.Num();
	} 

	AActor GetDestinationArea(int DestinationIndex) const override
	{
		if (!HasDestination(DestinationIndex))
			return nullptr;
		return Destinations[DestinationIndex].LocalArc.LandArea;
	}

	FRotator GetDestinationLandingRotation(int DestinationIndex) const
	{
		if (!HasDestination(DestinationIndex))
			return WorldRotation;
		return WorldTransform.TransformVectorNoScale(Destinations[DestinationIndex].LocalArc.LandTangent).Rotation();
	}

	FVector GetDestinationLandingTangent(int DestinationIndex) const
	{
		if (!HasDestination(DestinationIndex))
			return FVector::ZeroVector;
		return WorldTransform.TransformVectorNoScale(Destinations[DestinationIndex].LocalArc.LandTangent);
	}

	bool GetTraversalArc(int DestinationIndex, FTraversalArc& OutArc) const
	{
		if (!HasDestination(DestinationIndex))
			return false;
		// We could cache this at beginplay for any non-mobile scenepoint if it ever becomes expensive
		const FArcTraversalScenepointDestination& Dest = Destinations[DestinationIndex];	
		OutArc = Dest.LocalArc;
		OutArc.LaunchLocation = WorldLocation;
		OutArc.LaunchTangent = WorldTransform.TransformVectorNoScale(Dest.LocalArc.LaunchTangent);
		OutArc.LandLocation = WorldTransform.TransformPosition(Dest.LocalArc.LandLocation);
		OutArc.LandTangent = WorldTransform.TransformVectorNoScale(Dest.LocalArc.LandTangent);
		return true;
	}

	bool IsAtDestination(int DestinationIndex, AHazeActor Actor) const override
	{
		if (!HasDestination(DestinationIndex))
			return false;

		FArcTraversalScenepointDestination Dest = Destinations[DestinationIndex];	
		FVector Destination = WorldTransform.TransformPosition(Dest.LocalArc.LandLocation);
		float Range = Dest.LandRadius;
		if (Actor.ActorLocation.IsWithinDist(Destination, Range))
			return true;
		return false;
	}
	
	void ClearDestinations() override
	{
		Destinations.Empty();
	}
}
