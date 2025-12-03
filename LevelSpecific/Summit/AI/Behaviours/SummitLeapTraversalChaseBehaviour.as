class USummitLeapTraversalChaseBehaviour : UBasicBehaviour
{
	default Requirements.Add(EBasicBehaviourRequirement::Movement);
	default Requirements.Add(EBasicBehaviourRequirement::Focus);

	UTrajectoryTraversalComponent TraversalComp;
	UBasicAITraversalSettings TraversalSettings;

	UTrajectoryTraversalScenepoint LaunchPoint;
	int Destination;
	FTraversalTrajectory TraversalTrajectory;
	bool bTraversing;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Super::Setup();
		TraversalComp = UTrajectoryTraversalComponent::Get(Owner);
		TraversalSettings = UBasicAITraversalSettings::GetSettings(Owner);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (!Super::ShouldActivate())
			return false;
		if (!TargetComp.HasValidTarget())
			return false;
		if (TraversalComp.CurrentArea == nullptr)
			return false;
		if (TraversalComp.CurrentArea.bTransitArea)
			return true; // Always chase out of a transit area
		if (Owner.ActorLocation.IsWithinDist(TargetComp.Target.ActorLocation, TraversalSettings.ChaseMinRange))
			return false;
		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (Super::ShouldDeactivate())
			return true;
		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		Super::OnActivated();
		bTraversing = false;
		
		if (!HasControl())
			return;

		LaunchPoint = nullptr;

		// Skip traverse if we're already in the same navmesh area as target 
		// Since it's expensive we don't test this in ShouldActivate
		FVector TargetLoc = TargetComp.Target.ActorLocation;
		if (Pathfinding::HasPath(Owner.ActorLocation, TargetLoc))
			return;

		// TODO: Use proper pathfinding to determine which area we should traverse to
		FVector ToTarget = TargetLoc - Owner.ActorLocation;
		float BestDistSqr = BIG_NUMBER;
		UTrajectoryTraversalScenepoint BadPoint = nullptr;
		int BadDestination = -1;
		float BestBadDistSqr = BIG_NUMBER;
		TArray<UTraversalScenepointComponent> TraversalPoints;
		TraversalComp.CurrentArea.GetTraversalPoints(TraversalComp.Method, TraversalPoints);
		for (UTraversalScenepointComponent Pt : TraversalPoints)
		{
			UTrajectoryTraversalScenepoint Point = Cast<UTrajectoryTraversalScenepoint>(Pt);
			if (Point == nullptr)
				continue;

			// Skip points where we need to move past target
			if (ToTarget.DotProduct(TargetLoc - Point.WorldLocation) < 0.0)
				continue;

			for (int iDest = 0; iDest < Point.GetDestinationCount(); iDest++)
			{
				// Transit areas and points where we have to pass beyond the target 
				// will only be considered if there are no better points.
				FVector DestLoc = Point.GetDestination(iDest);
				FVector DestToTarget = TargetLoc - DestLoc;
				float DistSqr = DestToTarget.SizeSquared();
				bool bGoodPoint = (DestToTarget.DotProduct(ToTarget) > 0.0);
				if (bGoodPoint)
				{
					ATraversalAreaActor DestArea = Cast<ATraversalAreaActor>(Point.GetDestinationArea(iDest));
					if ((DestArea == nullptr) || DestArea.bTransitArea)
						bGoodPoint = false;
				}
				if (bGoodPoint)
				{
					// Good destination!
					if (DistSqr < BestDistSqr)
					{
						LaunchPoint = Point;
						Destination = iDest;
						BestDistSqr = DistSqr;	
					}
				}
				else if (DistSqr < Math::Min(BestBadDistSqr, BestDistSqr))
				{
					BadPoint = Point;
					BadDestination = iDest;
					BestBadDistSqr = DistSqr;
				}
			}
		}
		if (LaunchPoint == nullptr)
		{
			LaunchPoint = BadPoint;
			Destination = BadDestination;
		}
		if (LaunchPoint != nullptr)
			LaunchPoint.GetTraversalTrajectory(Destination, TraversalTrajectory);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if (LaunchPoint == nullptr)
		{
			// Try again later
			Cooldown.Set(5.0);
			return;			
		}

		DestinationComp.RotateTowards(TargetComp.Target);

		// Have we reached point to launch away from yet?
		if (!bTraversing && LaunchPoint.IsAt(Owner))
			CrumbStartTraversal();

		if (!bTraversing)
		{
			// Still moving to point from which we launch traversal
			DestinationComp.MoveTowards(LaunchPoint.WorldLocation, BasicSettings.ChaseMoveSpeed);
			AnimComp.RequestFeature(AnimComp.BaseMovementTag, EBasicBehaviourPriority::Low, this);

			// TODO: Check if we've been knocked off area
		}
		else if (!TraversalComp.IsAtDestination(TraversalTrajectory.LandLocation))
		{
			// Traversing to destination
			TraversalComp.Traverse(TraversalTrajectory);
			AnimComp.RequestFeature(LocomotionFeatureAISummitTags::TraverseLeap, EBasicBehaviourPriority::Medium, this);
		}
		else
		{
			// We're there!
			ATraversalAreaActor DestinationArea = Cast<ATraversalAreaActor>(LaunchPoint.GetDestinationArea(Destination));
			TraversalComp.SetCurrentArea(DestinationArea);
			
			// TODO: determine how long we should pause before moving onto next traversal 
			if (DestinationArea.bTransitArea)
				Cooldown.Set(0.0);
			else
				Cooldown.Set(1.0);
		}
	}

	UFUNCTION(CrumbFunction)
	void CrumbStartTraversal()
	{
		bTraversing = true;
	}
}