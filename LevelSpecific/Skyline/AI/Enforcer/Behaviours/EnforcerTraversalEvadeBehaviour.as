class UEnforcerTraversalEvadeBehaviour : UBasicBehaviour
{
	default Requirements.Add(EBasicBehaviourRequirement::Movement);
	
	UArcTraversalComponent TraversalComp;
	UBasicAITraversalSettings TraversalSettings;
	UTraversalManager TraversalManager;
	UEnforcerJetpackComponent JetpackComp;
	UHazeActorRespawnableComponent RespawnComp;

	USkylineJetpackTraversalMethod TraversalMethod;
	FTraversalArc TraversalArc;

	float EvadeCheckCountdown;
	bool bEvade;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Super::Setup();
		TraversalComp = UArcTraversalComponent::Get(Owner);
		TraversalSettings = UBasicAITraversalSettings::GetSettings(Owner);
		JetpackComp = UEnforcerJetpackComponent::Get(Owner);
		RespawnComp = UHazeActorRespawnableComponent::Get(Owner);
		RespawnComp.OnRespawn.AddUFunction(this, n"Reset");
		Reset();

		TraversalMethod = NewObject(Owner, USkylineJetpackTraversalMethod);
		TraversalMethod.MinRange = TraversalSettings.EvadeDestinationMinRange; 
		TraversalMethod.MaxRange = TraversalSettings.EvadeDestinationMaxRange;
		
		// We have no additional final destination, only launch point destination
		TraversalMethod.DirectArcs.Options.Remove(EDirectTraversalArcOption::Destination);
	}

	UFUNCTION(NotBlueprintCallable)
	private void Reset()
	{
		EvadeCheckCountdown = TraversalSettings.EvadeCheckInterval * Math::RandRange(0.0, 1.0);
		bEvade = false;
	}

	UFUNCTION(BlueprintOverride)
	void PreTick(float DeltaTime)
	{
		// There are some expensive checks that may not be always available 
		// for us to use, so do those in PreTick instead of ShouldActivate, 
		// but only when we're actually interested in performing a 
		//traversal evade
		if (!HasControl())
			return;
		if (IsActive() || IsBlocked())
			return;
		if (!Cooldown.IsOver() || !Requirements.CanClaim(BehaviourComp, this))
			return;		
		if (TargetComp.Target == nullptr)
			return;
		if (!TargetComp.Target.ActorCenterLocation.IsWithinDist(Owner.ActorCenterLocation, TraversalSettings.EvadeRange))
			return;

		// We count down time to check for evade whenever all other conditions are met
		// Note that this means we'll evade earlier if we we're previously approached by target.
		EvadeCheckCountdown -= DeltaTime;
		if (EvadeCheckCountdown > 0.0)
			return;

		// We need to know current area to find traversal points
		if (TraversalComp.CurrentArea == nullptr)
			return;	

		// We need to get this after setup; this will only exist after traversal areas 
		// have begun play and will be removed when all traversal areas have streamed out
		if (TraversalManager == nullptr)
			TraversalManager = Traversal::GetManager();
		if (TraversalManager == nullptr)
			return;
		if (!TraversalManager.CanClaimTraversalCheck(TraversalMethod))
			return; 
		// Claim by traversal method to allow that to do traversal checks as well
		TraversalManager.ClaimTraversalCheck(TraversalMethod);

		// We want a point with a destination away from the player. Some randomness is fine.
		// TODO: We really don't need to calculate this every tick!
		UArcTraversalScenepoint EvadePoint = nullptr; 
		int EvadeDestination = 0;
		FVector OwnLoc = Owner.ActorCenterLocation;
		FVector AwayFromTarget = (OwnLoc - TargetComp.Target.ActorCenterLocation).GetSafeNormal(); 
		float BestScore = -BIG_NUMBER;
		bool bBestPointBehind = false;
		TArray<UTraversalScenepointComponent> TraversalPoints;
		TraversalComp.CurrentArea.GetTraversalPoints(TraversalComp.Method, TraversalPoints);
		for (UTraversalScenepointComponent Scenepoint : TraversalPoints)
		{
			UArcTraversalScenepoint Point = Cast<UArcTraversalScenepoint>(Scenepoint);
			if (Point == nullptr)
				continue;

			// We can't try to evade to a point beyond max range (we assume actual destination will be even further away)
			if (!Point.WorldLocation.IsWithinDist(OwnLoc, TraversalSettings.EvadeDestinationMaxRange))
				continue;

			// Points that lie towards player may be acceptable as long as their destinations are away, but we prefer not to use them
			float PointDot = AwayFromTarget.DotProduct((Point.WorldLocation - OwnLoc).GetSafeNormal());
			float PointScore = (PointDot < 0.0) ? Math::Square(PointDot + 1.0) * 0.1 : 0.1 + PointDot * 0.9; // 0..0.1 behind player
			for (int iDest = 0; iDest < Point.GetDestinationCount(); iDest++)
			{
				FVector Destination = Point.GetDestination(iDest);
				if (Destination.IsWithinDist(OwnLoc, TraversalSettings.EvadeDestinationMinRange))
					continue;
				float DestDotDist = AwayFromTarget.DotProduct(Destination - OwnLoc); 
				float Score =  PointScore * DestDotDist * Math::RandRange(0.5, 1.0);
				if (Score > BestScore)
				{
					EvadePoint = Point;
					EvadeDestination = iDest;
					bBestPointBehind = (PointScore < 0.1);
					BestScore = Score;
				}	
			}
		}
		if (EvadePoint == nullptr)
			return;

		// Only try traversing to evade point itself if it's away from player.
		if (bBestPointBehind)
			TraversalMethod.DirectArcs.Options.Remove(EDirectTraversalArcOption::LaunchpointStraight);
		else
			TraversalMethod.DirectArcs.Options.AddUnique(EDirectTraversalArcOption::LaunchpointStraight);

		bEvade = TraversalMethod.CanStartDirectTraversal(Owner, EvadePoint, EvadeDestination, TraversalArc);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (!Super::ShouldActivate())
			return false;
		if (!bEvade)
			return false;
		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (Super::ShouldDeactivate())
			return true;
		if (!bEvade)
			return true;
		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		Super::OnActivated();

		if (!HasControl())
			return;

		JetpackComp.StartJetpack();
		UEnforcerJetpackEffectHandler::Trigger_JetpackStart(Owner);
		AnimComp.RequestFeature(LocomotionFeatureAISkylineTags::JetpackTraverse, EBasicBehaviourPriority::Medium, this);
	}
	
	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		Super::OnDeactivated();
		JetpackComp.StopJetpack();
		Reset();
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		// Movement and crumb-synced stuff only below
		if (!HasControl())
			return;

		if (!TraversalComp.IsAtDestination(TraversalArc.LandLocation))
		{
			// Traversing to destination
			TraversalComp.Traverse(TraversalArc, TraversalSettings.EntranceSpeed);
		}
		else
		{
			// We're there!
			bEvade = false;
			TraversalComp.SetCurrentArea(TraversalArc.LandArea);
			UEnforcerJetpackEffectHandler::Trigger_JetpackEnd(Owner);
			AnimComp.RequestFeature(LocomotionFeatureAISkylineTags::JetpackTraverse, SubTagAIJetpackTraverse::Land, EBasicBehaviourPriority::Medium, this);
		}

#if EDITOR
		//Owner.bHazeEditorOnlyDebugBool  = true;
		if (Owner.bHazeEditorOnlyDebugBool)
			TraversalArc.DrawDebug(FLinearColor::Yellow, 0.0);
#endif		
	}
}