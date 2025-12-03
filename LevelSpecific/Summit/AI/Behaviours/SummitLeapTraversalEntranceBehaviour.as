class USummitLeapTraversalEntranceBehaviour : UBasicBehaviour
{
	default Requirements.Add(EBasicBehaviourRequirement::Movement);
	default Requirements.AddBlock(EBasicBehaviourRequirement::Weapon);
	
	UTrajectoryTraversalComponent TraversalComp;
	UBasicAITraversalSettings TraversalSettings;
	UTraversalManager TraversalManager;
	UScenepointUserComponent ScenepointUserComp;
	UHazeActorRespawnableComponent RespawnComp;
	UBasicAIEntranceComponent EntranceComp;

	UTrajectoryTraversalScenepoint LaunchPoint;
	int Destination; 
	bool bTraversing;
	FTraversalTrajectory TraversalTrajectory;
	USummitLeapTraversalMethod TraversalMethod;	

	UScenepointComponent EntranceScenepoint;
	AActor EntranceScenepointArea;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Super::Setup();
		TraversalComp = UTrajectoryTraversalComponent::Get(Owner);
		TraversalSettings = UBasicAITraversalSettings::GetSettings(Owner);
		RespawnComp = UHazeActorRespawnableComponent::Get(Owner);
		RespawnComp.OnRespawn.AddUFunction(this, n"OnReset");
		ScenepointUserComp = UScenepointUserComponent::Get(Owner);
		EntranceComp = UBasicAIEntranceComponent::GetOrCreate(Owner);
		
		TraversalMethod = Cast<USummitLeapTraversalMethod>(NewObject(Owner, TraversalComp.Method));
		TraversalMethod.MinRange = TraversalSettings.EntranceMinRange; 
		TraversalMethod.MaxRange = TraversalSettings.EntranceMaxRange;
	}

	UFUNCTION()
	private void OnReset()
	{
		EntranceScenepoint = nullptr;
	}

	UFUNCTION(BlueprintOverride)
	void PreTick(float DeltaTime)
	{
		// There are some expensive checks that may not be always available 
		// for us to use, so do those in PreTick instead of ShouldActivate, 
		// but only when we're actually interested in performing a 
		// traversal entrance
		if (EntranceComp.bHasCompletedEntry)
			return;
		if (!HasControl())
			return;
		if (IsActive() || IsBlocked())
			return;
		if (!Cooldown.IsOver() || !Requirements.CanClaim(BehaviourComp, this))
			return;		

		// We need to know where we are to be able to traverse
		if (TraversalComp.CurrentArea == nullptr)
			return;

		// To activate we need to know in which area entrance scenepoint is. 
		EntranceScenepoint = Scenepoint::GetEntryScenePoint(ScenepointUserComp, RespawnComp);	
		if (EntranceScenepoint == nullptr)
		{
			EntranceScenepointArea = nullptr;
			return;
		}

		// We need to get this after setup; this will only exist after traversal areas 
		// have begun play and will be removed when all traversal areas have streamed out
		if (TraversalManager == nullptr)
			TraversalManager = Traversal::GetManager();
		if (TraversalManager == nullptr)
			return;

		EntranceScenepointArea = TraversalManager.GetCachedScenepointArea(EntranceScenepoint);
		if ((EntranceScenepointArea == nullptr) && TraversalManager.CanClaimTraversalCheck(this))
		{
			TraversalManager.ClaimTraversalCheck(this);
			EntranceScenepointArea = TraversalManager.FindTraversalArea(EntranceScenepoint);					
		}
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (!Super::ShouldActivate())
			return false;
		if(EntranceComp.bHasStartedEntry)
			return false;
		if (EntranceComp.bHasCompletedEntry)
			return false;
		if (EntranceScenepoint == nullptr)
			return false;
		if (EntranceScenepointArea == nullptr)
			return false;
		if (TraversalComp.CurrentArea == nullptr)
			return false;
		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (Super::ShouldDeactivate())
			return true;
		if (EntranceComp.bHasCompletedEntry)
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
		if (TraversalComp.CurrentArea == EntranceScenepointArea)
		{
			// We're in the correct area already, no need to set launch point
			return;
		}

		// TODO: Use proper pathfinding to determine which area we should traverse to
		FVector TargetLoc = EntranceScenepoint.WorldLocation;
		FVector ToTarget = TargetLoc - Owner.ActorLocation;
		float BestDistSqr = BIG_NUMBER;
		UTrajectoryTraversalScenepoint BeyondPoint = nullptr;
		int BeyondDestination = -1;
		float BestBeyondDistSqr = BIG_NUMBER;
		TArray<UTraversalScenepointComponent> TraversalPoints;
		TraversalComp.CurrentArea.GetTraversalPoints(TraversalComp.Method, TraversalPoints);
		for (UTraversalScenepointComponent Scenepoint : TraversalPoints)
		{
			UTrajectoryTraversalScenepoint Point = Cast<UTrajectoryTraversalScenepoint>(Scenepoint);
			if (Point == nullptr)
				continue;

			// Skip points where we need to move past target
			if (ToTarget.DotProduct(TargetLoc - Point.WorldLocation) < 0.0)
				continue;

			for (int iDest = 0; iDest < Point.GetDestinationCount(); iDest++)
			{
				FVector DestLoc = Point.GetDestination(iDest);
				FVector DestToTarget = TargetLoc - DestLoc;
				float DistSqr = DestToTarget.SizeSquared();
				if (DestToTarget.DotProduct(ToTarget) > 0.0)
				{
					// Between us and target, good destination!
					if (DistSqr < BestDistSqr)
					{
						LaunchPoint = Point;
						Destination = iDest;
						BestDistSqr = DistSqr;	
					}
				}
				else if (DistSqr < Math::Min(BestBeyondDistSqr, BestDistSqr))
				{
					// To reach destination we will pass target, keep as backup
					BeyondPoint = Point;
					BeyondDestination = iDest;
					BestBeyondDistSqr = DistSqr;
				}
			}
		}
		if (LaunchPoint == nullptr)
		{
			LaunchPoint = BeyondPoint;
			Destination = BeyondDestination;
		}
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		// Movement and crumb-synced stuff only below
		if (!HasControl())
			return;

		if ((EntranceScenepointArea != TraversalComp.CurrentArea) && (LaunchPoint == nullptr))		
		{
			// We need to traverse to some other area, but haven't found a suitable point to launch from. Try again later.
			Cooldown.Set(5.0);
			return;			
		}

		// Should we start traversal?
		if (!bTraversing)
		{
			if (CanStartTraversal(LaunchPoint, TraversalTrajectory))
				CrumbStartTraversal();
			else if (TraversalMethod.CanStartDirectTraversal(Owner, EntranceScenepoint, LaunchPoint, Destination, TraversalTrajectory))
				CrumbStartTraversal();
		}
		
		if (!bTraversing)
		{
			// Moving along ground to point from which we can leap or final destination.
			FVector MoveDestination = (LaunchPoint == nullptr) ? EntranceScenepoint.WorldLocation : LaunchPoint.WorldLocation;
			DestinationComp.MoveTowards(MoveDestination, BasicSettings.ScenepointEntryMoveSpeed);
			AnimComp.RequestFeature(AnimComp.BaseMovementTag, EBasicBehaviourPriority::Low, this);
		}
		else if (!TraversalComp.IsAtDestination(TraversalTrajectory.LandLocation))
		{
			// Traversing to destination (note that trajectory itself decides velocity)
			TraversalComp.Traverse(TraversalTrajectory);
		}
		else
		{
			// We're there!
			bTraversing = false;
			Cooldown.Set(0.0);
			TraversalComp.SetCurrentArea(TraversalTrajectory.LandArea);
		}

		if (!bTraversing &&  
			(TraversalComp.CurrentArea == EntranceScenepointArea) && 
			EntranceScenepoint.IsAt(Owner))
		{
			// We have arrived at our final destination!
			EntranceComp.bHasCompletedEntry = true;
		}
	}

	bool CanStartTraversal(UTrajectoryTraversalScenepoint Traversalpoint, FTraversalTrajectory& OutTrajectory)
	{
		if (bTraversing)
			return false; // Already traversing

		if (Traversalpoint == nullptr)
			return false; // Need to use direct traversal

		// Have we reached point to launch away from yet?
		if (Traversalpoint.IsAt(Owner))
		{
			Traversalpoint.GetTraversalTrajectory(Destination, OutTrajectory);
			return true;
		}
		return false;
	}

	UFUNCTION(CrumbFunction)
	void CrumbStartTraversal()
	{
		bTraversing = true;
		AnimComp.RequestFeature(LocomotionFeatureAISummitTags::TraverseLeap, EBasicBehaviourPriority::Medium, this);
	}
}