class USkylineJetpackTraversalMethod : UTraversalMethod
{
	default ScenepointClass = UArcTraversalScenepoint;
	default VisualizationColor = FLinearColor::Green;
	default MaxRange = 2000.0;
	default ScenepointInwardsOffset = 100;

	UTraversalManager TraversalManager;
	FDirectTraversalArcOptions DirectArcs;

	bool IsTraversable(FHazeNavmeshEdge Edge) override
	{
		// All edges can be traversed from in the highway scenario
		return true;
	}

	bool CanTraverse(UScenepointComponent From, UScenepointComponent To) override
	{
		if (!IsInRange(From, To))
			return false;

		FTraversalArc Arc;
		if (!GetArc(From, To, Arc))
			return false;

		// In highway there are never any real obstructions, but we do get obstructed by the 
		// highway ring/tube thingy for some reason. Thus we just skip tracing. 		
		// FVector LaunchOffset = From.UpVector * Cast<UArcTraversalScenepoint>(From).TraversalHeight;
		// FVector LandOffset = To.UpVector * Cast<UArcTraversalScenepoint>(To).TraversalHeight;
		//if (!Arc.CanTraverse(LaunchOffset, LandOffset))
		//	return false;

		// We can go there!
		return true;
	}
	
	void AddTraversalPath(UScenepointComponent From, UScenepointComponent To) override
	{
		Super::AddTraversalPath(From, To);

		FTraversalArc Arc;
		if (!GetArc(From, To, Arc))
			return;

		UArcTraversalScenepoint Launch = Cast<UArcTraversalScenepoint>(From);
		Launch.AddDestination(Arc, To.Owner, To.Radius);
	}

	bool GetArc(UScenepointComponent From, UScenepointComponent To, FTraversalArc& OutArc)
	{
		UArcTraversalScenepoint Launch = Cast<UArcTraversalScenepoint>(From);
		UArcTraversalScenepoint Land = Cast<UArcTraversalScenepoint>(To);
		if ((Launch == nullptr) || (Land == nullptr))
			return false;

		OutArc.LaunchLocation = Launch.WorldLocation;
		OutArc.LaunchTangent = Traversal::GetLaunchDirection(Launch.WorldRotation, Launch.TraversalPitch) * Launch.LaunchTangentLength;
		OutArc.LandLocation = Land.WorldLocation;
		OutArc.LandTangent = -Traversal::GetLaunchDirection(Land.WorldRotation, Land.TraversalPitch) * Land.LandTangentLength; 
		return true;
	}

	bool CanStartDirectTraversal(AHazeActor Traverser, UScenepointComponent DestinationPoint, FTraversalArc& OutArc)
	{
		return CanStartDirectTraversal(Traverser, DestinationPoint, nullptr, -1, OutArc);
	}

	bool CanStartDirectTraversal(AHazeActor Traverser, UScenepointComponent LaunchPoint, int iDestination, FTraversalArc& OutArc)
	{
		return CanStartDirectTraversal(Traverser, nullptr, Cast<UArcTraversalScenepoint>(LaunchPoint), iDestination, OutArc);
	}

	bool CanStartDirectTraversal(AHazeActor Traverser, UScenepointComponent DestinationPoint, UTraversalScenepointComponent LaunchPoint, int iDestination, FTraversalArc& OutArc)
	{
		if (Traverser == nullptr)
			return false;

		if (TraversalManager == nullptr)
			TraversalManager = Traversal::GetManager();
		if (!devEnsure(TraversalManager != nullptr, "Tried to do a direct traversal check for " + Traverser.Name + " when there is no traversal manager. Place at least one traversal area in your level."))
			return false;

		if (DirectArcs.Options.Num() == 0)
			return false;

		if (!TraversalManager.CanClaimTraversalCheck(this))
			return false; // Soneone else has checked traversal, we should wait.

		// We're free to check if we can traverse directly to destination
		TraversalManager.ClaimTraversalCheck(this);

		if (!GetDirectArc(Traverser, DestinationPoint, Cast<UArcTraversalScenepoint>(LaunchPoint), iDestination, OutArc))
			return false;
		
		FVector Offset = Traverser.ActorUpVector * LaunchPoint.TraversalHeight;
#if EDITOR
		//Traverser.bHazeEditorOnlyDebugBool = true;
		if (Traverser.bHazeEditorOnlyDebugBool)
		{
			FLinearColor Color = OutArc.CanTraverse(Offset, Offset) ? FLinearColor::Green : FLinearColor::Red;
			OutArc.DrawDebug(Color, 10.0);
		}
#endif
		return OutArc.CanTraverse(Offset, Offset);
	}

	private bool GetDirectArc(AHazeActor Traverser, UScenepointComponent DestinationPoint, UArcTraversalScenepoint LaunchPoint, int iDestination, FTraversalArc& OutArc)
	{
		FTraversalArc Arc;
		for (int i = 0; i < DirectArcs.Options.Num(); i++)
		{
			EDirectTraversalArcOption Option = DirectArcs.ConsumeOption();
			if (!GetDirectArcByOption(Traverser, Option, DestinationPoint, LaunchPoint, iDestination, Arc))
				continue; 
			if (!Traverser.ActorLocation.IsWithinDist(Arc.LandLocation, MaxRange))
				continue; 
			if (Traverser.ActorLocation.IsWithinDist(Arc.LandLocation, MinRange))
				continue; 
			// Found valid arc to test!
			OutArc = Arc;
			return true;					
		}
		// We've exhausted the available options		
		return false; 
	}

	private bool GetDirectArcByOption(AHazeActor Traverser, EDirectTraversalArcOption Option, UScenepointComponent DestinationPoint, UArcTraversalScenepoint LaunchPoint, int iDestination, FTraversalArc& OutArc)
	{
		switch (Option)
		{
			case EDirectTraversalArcOption::Destination:
			{
				if (DestinationPoint == nullptr)
					return false;
				AActor DestinationArea = TraversalManager.GetCachedScenepointArea(DestinationPoint);
				if (DestinationArea == nullptr)
					return false;
				
				// Traverse to destination, preferrably so we land somewhat aligned
				OutArc.LaunchLocation = Traverser.ActorLocation;
				OutArc.LaunchTangent = Traversal::GetLaunchDirection(Traverser.ActorVelocity.Rotation(), 45.0) * 1000.0;
				OutArc.LandLocation = DestinationPoint.WorldLocation;
				OutArc.LandTangent = Traversal::GetLandDirection(DestinationPoint.WorldRotation.Compose(FRotator(0.0, 180.0, 0.0)), 45.0) * 1000.0;
				OutArc.LandArea = DestinationArea;
				return true;
			}
			
			case EDirectTraversalArcOption::LaunchDestination:
			case EDirectTraversalArcOption::LaunchDestinationStraight:
			{
				if (LaunchPoint == nullptr)
					return false;
				if (!LaunchPoint.HasDestination(iDestination))
					return false;

				// Use launch destination
				OutArc.LaunchLocation = Traverser.ActorLocation;
				OutArc.LaunchTangent = Traversal::GetLaunchDirection(Traverser.ActorVelocity.Rotation(), 45.0) * 1000.0;
				OutArc.LandLocation = LaunchPoint.GetDestination(iDestination);
				if (Option == EDirectTraversalArcOption::LaunchDestination)
					OutArc.LandTangent = LaunchPoint.GetDestinationLandingTangent(iDestination); 
				else // LaunchDestinationStraight
					OutArc.LandTangent = Traversal::GetLandDirection((Traverser.ActorLocation - OutArc.LandLocation).Rotation(), 45.0) * 1000.0;
				OutArc.LandArea = LaunchPoint.GetDestinationArea(iDestination);
				return true;
			}

			case EDirectTraversalArcOption::LaunchpointStraight:
			{
				if (LaunchPoint == nullptr)
					return false;
				AActor LaunchArea = TraversalManager.GetCachedScenepointArea(LaunchPoint);
				if (LaunchArea == nullptr)
					return false;

				// Ignore launch point's own land tangent; we're approaching from within area
				// Also, use shorter tangent on both launch and land
				FVector ToLaunchpoint = (LaunchPoint.WorldLocation - Traverser.ActorLocation);
				float TangentLength = Math::Min(ToLaunchpoint.Size() * 0.2, 1000.0);
				OutArc.LaunchLocation = Traverser.ActorLocation;
				OutArc.LaunchTangent = Traversal::GetLaunchDirection(Traverser.ActorVelocity.Rotation(), 45.0) * TangentLength;
				OutArc.LandLocation = LaunchPoint.WorldLocation;
				OutArc.LandTangent = Traversal::GetLandDirection((-ToLaunchpoint).Rotation(), 45.0) * TangentLength; 
				OutArc.LandArea = LaunchArea;
				return true;
			}
		}
	}
}
