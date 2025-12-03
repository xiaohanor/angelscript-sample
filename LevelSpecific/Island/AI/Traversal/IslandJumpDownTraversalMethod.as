class UIslandJumpDownTraversalMethod : UTraversalMethod
{
	default ScenepointClass = UIslandTrajectoryTraversalScenepointComponent;
	default VisualizationColor = FLinearColor::Yellow;

	default MinRange = 10.0;
	default MaxRange = 1000.0;
	float MaxLeapSpeed = 1.2*1250.0;
	float Gravity = 982.0;
	float IdealAngle = 10.0;
	float DefaultHeight = 15.0;

	UTraversalManager TraversalManager;

	default MethodName = n"IslandJumpDownTraversalMethod";

	// Checked before adding a new trajectory to a Scenepoint.
	bool CanTraverse(UScenepointComponent From, UScenepointComponent To) override
	{
		if (!IsInRange(From, To))
			return false;

		if (From.WorldLocation.Z <= To.WorldLocation.Z)
			return false;

		UIslandTrajectoryTraversalScenepointComponent IslandTrajectoryFrom = Cast<UIslandTrajectoryTraversalScenepointComponent>(From);
		float Height = IslandTrajectoryFrom != nullptr && IslandTrajectoryFrom.OverrideHeight >= 0.0 ?  IslandTrajectoryFrom.OverrideHeight : DefaultHeight;
		float GravityFactor = IslandTrajectoryFrom != nullptr && IslandTrajectoryFrom.OverrideGravityFactor >= 0.0 ?  IslandTrajectoryFrom.OverrideGravityFactor : 1.0;
		if (IslandTrajectoryFrom.MaxLeapDistance2D > 0.0)
		{
			FVector ToDest = To.WorldLocation - From.WorldLocation;
			float HDist = ToDest.Size2D();
			if (HDist > IslandTrajectoryFrom.MaxLeapDistance2D)
				return false;
		}

		FTraversalTrajectory Trajectory;
		if (!GetTrajectory(From.WorldLocation, To.WorldLocation, Height, GravityFactor, Trajectory))
			return false;

		FVector LeapOffset = From.UpVector * Cast<UTrajectoryTraversalScenepoint>(From).TraversalHeight;
		FVector LandOffset = To.UpVector * Cast<UTrajectoryTraversalScenepoint>(To).TraversalHeight;
		if (!Trajectory.CanTraverse(LeapOffset, LandOffset))
			return false;

		// We can go there!
		return true;
	}

	bool IsInRange(UScenepointComponent From, UScenepointComponent To) override
	{
		if ((From == nullptr) || (To == nullptr))
			return false;

		FVector FromLocation2D = From.WorldLocation;
		FromLocation2D.Y = 0;
		FVector ToLocation2D = To.WorldLocation;
		ToLocation2D.Y = 0;

		if (!FromLocation2D.IsWithinDist(ToLocation2D, MaxRange))
			return false;
		if (FromLocation2D.IsWithinDist(ToLocation2D, MinRange))
			return false;
		return true;
	}
	
	void AddTraversalPath(UScenepointComponent From, UScenepointComponent To) override
	{
		Super::AddTraversalPath(From, To);

		UIslandTrajectoryTraversalScenepointComponent IslandTrajectoryFrom = Cast<UIslandTrajectoryTraversalScenepointComponent>(From);
		float Height = IslandTrajectoryFrom != nullptr && IslandTrajectoryFrom.OverrideHeight >= 0.0 ?  IslandTrajectoryFrom.OverrideHeight : DefaultHeight;
		float GravityFactor = IslandTrajectoryFrom != nullptr && IslandTrajectoryFrom.OverrideGravityFactor >= 0.0 ?  IslandTrajectoryFrom.OverrideGravityFactor : 1.0;

		FTraversalTrajectory Trajectory;
		if (!GetTrajectory(From.WorldLocation, To.WorldLocation, Height, GravityFactor, Trajectory))
			return;

		// Remove any unwanted stored leaps
		if (IslandTrajectoryFrom.bLimitToOnlyShortestLeap)
		{
			for (int i = IslandTrajectoryFrom.Destinations.Num() - 1; i >= 0; i--)
			{
				if (IslandTrajectoryFrom.Destinations[i].LocalTrajectory.LandLocation.Size2D() > (Trajectory.LandLocation - Trajectory.LaunchLocation).Size2D()) // stored destinations are in local space.
					IslandTrajectoryFrom.Destinations.RemoveAt(i);
				else
					return;
			}
		}

		IslandTrajectoryFrom.AddDestination(Trajectory, To.Owner, To.Radius);
		Print("Added jump down destination");
	}

	bool GetTrajectory(FVector From, FVector To, float Height, float GravityFactor, FTraversalTrajectory& OutTrajectory)
	{
		if (MaxLeapSpeed < SMALL_NUMBER)
			return false; // Too weak!

		// Note: this assumes worldup == 0,0,1
		FVector ToDest = To - From;	
		float HDist = ToDest.Size2D(); 
		if (HDist < SMALL_NUMBER)
			return false; // Straight up or down is not a meaningful arc in this context

		//todo - get custom height from scenepoint

		FVector Vel = Trajectory::CalculateVelocityForPathWithHeight(From, To, Gravity * GravityFactor, Height);

		// Can't reach To location with MaxLeapSpeed
		if (Vel.Size() > MaxLeapSpeed)
			return false;

		OutTrajectory.LaunchLocation = From;
		OutTrajectory.LaunchVelocity = Vel;
		OutTrajectory.Gravity = FVector::UpVector * -Gravity * GravityFactor;
		OutTrajectory.LandLocation = To;
		return true;
	}
	
	bool IsTraversable(FHazeNavmeshEdge Edge) override
	{		
		return true;
	}
	
	bool IsDestinationCandidate(UScenepointComponent Scenepoint) override
	{
		return Scenepoint.IsA(UTrajectoryTraversalScenepoint);
	}
}
