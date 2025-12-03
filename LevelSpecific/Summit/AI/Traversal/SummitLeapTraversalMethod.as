class USummitLeapTraversalMethod : UTraversalMethod
{
	default ScenepointClass = UTrajectoryTraversalScenepoint;
	default VisualizationColor = FLinearColor::Green;

	float MaxLeapSpeed = 2000.0;
	float Gravity = 982.0;
	float IdealAngle = 45.0;

	UTraversalManager TraversalManager;
	FDirectTraversalTrajectoryOptions DirectTrajectories;

	bool CanTraverse(UScenepointComponent From, UScenepointComponent To) override
	{
		if (!IsInRange(From, To))
			return false;

		FTraversalTrajectory Trajectory;
		if (!GetTrajectory(From.WorldLocation, To.WorldLocation, Trajectory))
			return false;

		FVector LeapOffset = From.UpVector * Cast<UTrajectoryTraversalScenepoint>(From).TraversalHeight;
		FVector LandOffset = To.UpVector * Cast<UTrajectoryTraversalScenepoint>(To).TraversalHeight;
		if (!Trajectory.CanTraverse(LeapOffset, LandOffset))
			return false;

		// We can go there!
		return true;
	}
	
	void AddTraversalPath(UScenepointComponent From, UScenepointComponent To) override
	{
		Super::AddTraversalPath(From, To);

		FTraversalTrajectory Trajectory;
		if (!GetTrajectory(From.WorldLocation, To.WorldLocation, Trajectory))
			return;

		UTrajectoryTraversalScenepoint Leap = Cast<UTrajectoryTraversalScenepoint>(From);
		Leap.AddDestination(Trajectory, To.Owner, To.Radius);
		Print("Added destination");
	}

	bool GetTrajectory(FVector From, FVector To, FTraversalTrajectory& OutTrajectory)
	{
		if (MaxLeapSpeed < SMALL_NUMBER)
			return false; // Too weak!

		// Note: this assumes worldup == 0,0,1
		FVector ToDest = To - From;	
		float HDist = ToDest.Size2D(); 
		if (HDist < SMALL_NUMBER)
			return false; // Straight up or down is not a meaningful arc in this context
		float VDist = ToDest.Z;

		float LeapSpeed = MaxLeapSpeed;
		if (VDist < HDist)
		{
			// Use slightly more than speed needed to reach target at ideal angle.
			float IdealRadians = Math::DegreesToRadians(IdealAngle);
			float IdealCos = Math::Cos(IdealRadians);
			float IdealTan = Math::Tan(IdealRadians);
			float LeapSpeedIdeal = Math::Sqrt(Gravity * Math::Square(HDist) / (2.0 * Math::Square(IdealCos) * ((IdealTan * HDist) - VDist))); 
			if (LeapSpeedIdeal * 1.1 < MaxLeapSpeed)
				LeapSpeed = LeapSpeedIdeal * 1.1;
		}
		float SpeedSqr = Math::Square(LeapSpeed); 
		float Discriminant = Math::Square(SpeedSqr) - Gravity * ((Gravity * Math::Square(HDist)) + (2.0 * VDist * SpeedSqr));
		if (Discriminant < SMALL_NUMBER)
			return false; // Can't reach target with this speed and gravity, add code here if we want to allow speed increase or gravity decrease

		// Calculate height of leap tangent, either using high or low parabola
		float ParabolaSign = (IdealAngle < 45.0) ? -1.0 : 1.0;
		float LeapHeight = (SpeedSqr + ParabolaSign * Math::Sqrt(Discriminant)) / Gravity; // This is Tan(LeapAngle) * HDist
        FVector LeapDir = FVector(ToDest.X, ToDest.Y, LeapHeight).GetSafeNormal();

		OutTrajectory.LaunchLocation = From;
		OutTrajectory.LaunchVelocity = LeapDir * LeapSpeed;
		OutTrajectory.Gravity = FVector::UpVector * -Gravity;
		OutTrajectory.LandLocation = To;
		return true;
	}

	bool CanStartDirectTraversal(AHazeActor Traverser, UScenepointComponent DestinationPoint, FTraversalTrajectory& OutTrajectory)
	{
		return CanStartDirectTraversal(Traverser, DestinationPoint, nullptr, -1, OutTrajectory);
	}

	bool CanStartDirectTraversal(AHazeActor Traverser, UScenepointComponent DestinationPoint, UTraversalScenepointComponent LeapPoint, int iDestination, FTraversalTrajectory& OutTrajectory)
	{
		if (Traverser == nullptr)
			return false;

		if (TraversalManager == nullptr)
			TraversalManager = Traversal::GetManager();
		if (!devEnsure(TraversalManager != nullptr, "Tried to do a direct traversal check for " + Traverser.Name + " when there is no traversal manager. Place at least one traversal area in your level."))
			return false;

		if (DirectTrajectories.Options.Num() == 0)
			return false;

		if (!TraversalManager.CanClaimTraversalCheck(this))
			return false; // Soneone else has checked traversal, we should wait.

		// We're free to check if we can traverse directly to destination
		TraversalManager.ClaimTraversalCheck(this);

		if (!GetDirectTrajectory(Traverser, DestinationPoint, LeapPoint, iDestination, OutTrajectory))
			return false;
		
		FVector Offset = Traverser.ActorUpVector * ((LeapPoint != nullptr) ? LeapPoint.TraversalHeight : 100.0);
#if EDITOR
		//Traverser.bHazeEditorOnlyDebugBool = true;
		if (Traverser.bHazeEditorOnlyDebugBool)
		{
			FLinearColor Color = OutTrajectory.CanTraverse(Offset, Offset) ? FLinearColor::Green : FLinearColor::Red;
			OutTrajectory.DrawDebug(Color, 10.0);
		}
#endif
		return OutTrajectory.CanTraverse(Offset, Offset);
	}	

	private bool GetDirectTrajectory(AHazeActor Traverser, UScenepointComponent DestinationPoint, UTraversalScenepointComponent LeapPoint, int iDestination, FTraversalTrajectory& OutTrajectory)
	{
		FTraversalTrajectory Trajectory;
		for (int i = 0; i < DirectTrajectories.Options.Num(); i++)
		{
			EDirectTraversalTrajectoryOption Option = DirectTrajectories.ConsumeOption();
			if (!GetDirectTrajectoryByOption(Traverser, Option, DestinationPoint, LeapPoint, iDestination, Trajectory))
				continue; 
			if (!Traverser.ActorLocation.IsWithinDist(Trajectory.LandLocation, MaxRange))
				continue; 
			if (Traverser.ActorLocation.IsWithinDist(Trajectory.LandLocation, MinRange))
				continue; 
			// Found valid Trajectory to test!
			OutTrajectory = Trajectory;
			return true;					
		}
		// We've exhausted the available options		
		return false; 
	}

	private bool GetDirectTrajectoryByOption(AHazeActor Traverser, EDirectTraversalTrajectoryOption Option, UScenepointComponent DestinationPoint, UTraversalScenepointComponent LeapPoint, int iDestination, FTraversalTrajectory& OutTrajectory)
	{
		switch (Option)
		{
			case EDirectTraversalTrajectoryOption::Destination:
			{
				if (DestinationPoint == nullptr)
					return false;
				AActor DestinationArea = TraversalManager.GetCachedScenepointArea(DestinationPoint);
				if (DestinationArea == nullptr)
					return false;
				
				// Traverse to destination
				if (!GetTrajectory(Traverser.ActorLocation, DestinationPoint.WorldLocation, OutTrajectory))
					 return false;
				OutTrajectory.LandArea = DestinationArea;
				return true;
			}
			
			case EDirectTraversalTrajectoryOption::LaunchDestination:
			{
				if (LeapPoint == nullptr)
					return false;
				if (!LeapPoint.HasDestination(iDestination))
					return false;

				// Traverse to precalculated destination reachable from leap point
				if (!GetTrajectory(Traverser.ActorLocation, LeapPoint.GetDestination(iDestination), OutTrajectory))
					 return false;
				OutTrajectory.LandArea = LeapPoint.GetDestinationArea(iDestination);
				return true;
			}

			case EDirectTraversalTrajectoryOption::Launchpoint:
			{
				if (LeapPoint == nullptr)
					return false;
				AActor LeapArea = TraversalManager.GetCachedScenepointArea(LeapPoint);
				if (LeapArea == nullptr)
					return false;

				// Try to leap directly to point where there's a precalculated trajectory to continue leaping from
				if (!GetTrajectory(Traverser.ActorLocation, LeapPoint.WorldLocation, OutTrajectory))
					 return false;
				OutTrajectory.LandArea = LeapArea;
				return true;
			}
		}
	}
}
