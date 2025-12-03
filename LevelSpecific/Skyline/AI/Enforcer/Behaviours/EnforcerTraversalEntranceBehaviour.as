class UEnforcerTraversalEntranceBehaviour : UBasicBehaviour
{
	default Requirements.Add(EBasicBehaviourRequirement::Movement);
	default Requirements.AddBlock(EBasicBehaviourRequirement::Weapon);
	default CapabilityTags.Add(n"EnforcerTraversal");
	
	UArcTraversalComponent TraversalComp;
	UBasicAITraversalSettings TraversalSettings;
	UTraversalManager TraversalManager;
	UEnforcerJetpackComponent JetpackComp;
	UScenepointUserComponent ScenepointUserComp;
	UHazeActorRespawnableComponent RespawnComp;
	UBasicAIEntranceComponent EntranceComp;

	UArcTraversalScenepoint LaunchPoint;
	int Destination;
	bool bTraversing;
	FTraversalArc TraversalArc;	
	USkylineJetpackTraversalMethod TraversalMethod;

	UScenepointComponent EntranceScenepoint;
	AActor EntranceScenepointArea;
	bool bHasBlockedTraversal = false;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Super::Setup();
		TraversalComp = UArcTraversalComponent::Get(Owner);
		TraversalSettings = UBasicAITraversalSettings::GetSettings(Owner);
		JetpackComp = UEnforcerJetpackComponent::Get(Owner);
		RespawnComp = UHazeActorRespawnableComponent::Get(Owner);
		RespawnComp.OnRespawn.AddUFunction(this, n"OnReset");
		ScenepointUserComp = UScenepointUserComponent::Get(Owner);
		EntranceComp = UBasicAIEntranceComponent::GetOrCreate(Owner);

		TraversalMethod = Cast<USkylineJetpackTraversalMethod>(NewObject(Owner, TraversalComp.Method));
		TraversalMethod.MinRange = TraversalSettings.EntranceMinRange; 
		TraversalMethod.MaxRange = TraversalSettings.EntranceMaxRange;
	}

	UFUNCTION()
	private void OnReset()
	{
		EntranceScenepoint = nullptr;
		if (bHasBlockedTraversal)
		{
			Owner.UnblockCapabilities(n"EnforcerTraversal", this);
			bHasBlockedTraversal = false;
		}
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
		if (EntranceComp.bHasStartedEntry)
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

		if (!bHasBlockedTraversal)
		{
			Owner.BlockCapabilities(n"EnforcerTraversal", this);
			bHasBlockedTraversal = true;
		}

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
		UArcTraversalScenepoint BeyondPoint = nullptr;
		int BeyondDestination = -1;
		float BestBeyondDistSqr = BIG_NUMBER;
		TArray<UTraversalScenepointComponent> TraversalPoints;
		TraversalComp.CurrentArea.GetTraversalPoints(TraversalComp.Method, TraversalPoints);
		for (UTraversalScenepointComponent Scenepoint : TraversalPoints)
		{
			UArcTraversalScenepoint Point = Cast<UArcTraversalScenepoint>(Scenepoint);
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
	void OnDeactivated()
	{
		Super::OnDeactivated();
		JetpackComp.StopJetpack();
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

		if (!bTraversing)
		{
			if (CanStartTraversal(LaunchPoint, TraversalArc))
				CrumbStartTraversal();
			else if (TraversalMethod.CanStartDirectTraversal(Owner, EntranceScenepoint, LaunchPoint, Destination, TraversalArc))
				CrumbStartTraversal();
		}

		if (!bTraversing)
		{
			// Still moving to point from which we launch traversal
			FVector MoveDestination = (LaunchPoint == nullptr) ? EntranceScenepoint.WorldLocation : LaunchPoint.WorldLocation;
			DestinationComp.MoveTowards(MoveDestination, BasicSettings.ScenepointEntryMoveSpeed);
			AnimComp.RequestFeature(AnimComp.BaseMovementTag, EBasicBehaviourPriority::Low, this);
		}
		else if (!TraversalComp.IsAtDestination(TraversalArc.LandLocation))
		{
			// Traversing to destination
			TraversalComp.Traverse(TraversalArc, TraversalSettings.EntranceSpeed);
		}
		else
		{
			// We're there!
			bTraversing = false;
			Cooldown.Set(0.0);
			TraversalComp.SetCurrentArea(TraversalArc.LandArea);
			UEnforcerJetpackEffectHandler::Trigger_JetpackEnd(Owner);
			AnimComp.RequestFeature(LocomotionFeatureAISkylineTags::JetpackTraverse, SubTagAIJetpackTraverse::Land, EBasicBehaviourPriority::Medium, this);
		}

		if (!bTraversing &&  
			(TraversalComp.CurrentArea == EntranceScenepointArea) && 
			EntranceScenepoint.IsAt(Owner))
		{
			// We have arrived at our entrance scenepoint!
			EntranceComp.bHasCompletedEntry = true;
		}
	}

	bool CanStartTraversal(UArcTraversalScenepoint Traversalpoint, FTraversalArc& OutArc)
	{
		if (bTraversing)
			return false; // Already traversing

		if (Traversalpoint == nullptr)
			return false; // Need to use direct traversal	

		// Have we reached point to launch away from yet?
		if (Traversalpoint.IsAt(Owner))
		{
			Traversalpoint.GetTraversalArc(Destination, OutArc);
			return true;
		}
		return false;
	}

	UFUNCTION(CrumbFunction)
	void CrumbStartTraversal()
	{
		bTraversing = true;
		JetpackComp.StartJetpack();
		UEnforcerJetpackEffectHandler::Trigger_JetpackStart(Owner);
		AnimComp.RequestFeature(LocomotionFeatureAISkylineTags::JetpackTraverse, EBasicBehaviourPriority::Medium, this);
	}
}