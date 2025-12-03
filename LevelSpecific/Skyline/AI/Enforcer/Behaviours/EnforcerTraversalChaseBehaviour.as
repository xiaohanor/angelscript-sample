struct FEnforcerTraversalChaseBehaviourParams
{
	AHazeActor Target;
}

class UEnforcerTraversalChaseBehaviour : UBasicBehaviour
{
	default Requirements.Add(EBasicBehaviourRequirement::Movement);
	default Requirements.Add(EBasicBehaviourRequirement::Focus);

	UArcTraversalComponent TraversalComp;
	UBasicAITraversalSettings TraversalSettings;
	UEnforcerJetpackComponent JetpackComp;
	UGentlemanComponent GentComp;
	UGentlemanComponent GlobalGentComp;
	UBasicAIHealthComponent HealthComp;
	AHazeActor Target;

	UArcTraversalScenepoint LaunchPoint;
	int Destination;
	FTraversalArc TraversalArc;
	bool bTraversing;
	FVector StartLocation;
	float LandingTime;
	ATraversalAreaActor DestinationArea;
	UScenepointComponent DestinationPoint;
	bool bStartedJetpack;
	bool bHasInitialized;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Super::Setup();
		TraversalComp = UArcTraversalComponent::Get(Owner);
		TraversalSettings = UBasicAITraversalSettings::GetSettings(Owner);
		JetpackComp = UEnforcerJetpackComponent::Get(Owner);
		HealthComp = UBasicAIHealthComponent::Get(Owner);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate(FEnforcerTraversalChaseBehaviourParams& OutParams) const
	{
		if (!Super::ShouldActivate())
			return false;
		if (!TargetComp.HasValidTarget())
			return false;
		if (TraversalComp.CurrentArea == nullptr)
			return false;
 		if (Owner.ActorLocation.IsWithinDist(TargetComp.Target.ActorLocation, TraversalSettings.ChaseMinRange))
		   	return false;
		if (!UGentlemanComponent::GetOrCreate(TargetComp.Target).CanClaimToken(n"TraversalChase", this))
			return false;
		if (!UGentlemanComponent::GetOrCreate(Game::Mio).CanClaimToken(n"GlobalTraversalChase", this))
			return false;
		if (BehaviourComp.IsRequirementClaimed(EBasicBehaviourRequirement::Weapon))
		 	return false;
		OutParams.Target = TargetComp.Target;
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
	void OnActivated(FEnforcerTraversalChaseBehaviourParams Params)
	{
		Super::OnActivated();

		Target = Params.Target;
		bTraversing = false;
		LandingTime = BIG_NUMBER;
		DestinationArea = nullptr;
		DestinationPoint = nullptr;
		bStartedJetpack = false;

		GentComp = UGentlemanComponent::GetOrCreate(Target);
		GlobalGentComp = UGentlemanComponent::GetOrCreate(Game::Mio);
		GentComp.ClaimToken(n"TraversalChase", this);
		GlobalGentComp.ClaimToken(n"GlobalTraversalChase", this);
		
		if (!HasControl())
			return;

		LaunchPoint = nullptr;

		// Skip traverse if we're already in the same navmesh area as target 
		// Since it's expensive we don't test this in ShouldActivate
		FVector TargetLoc = Target.ActorLocation;
		if (Pathfinding::HasPath(Owner.ActorLocation, TargetLoc))
			return;

		// TODO: Use proper pathfinding to determine which area we should traverse to
		FVector ToTarget = TargetLoc - Owner.ActorLocation;
		float BestDistSqr = BIG_NUMBER;
		UArcTraversalScenepoint BadPoint = nullptr;
		int BadDestination = -1;
		float BestBadDistSqr = BIG_NUMBER;
		TArray<UTraversalScenepointComponent> TraversalPoints;
		TraversalComp.CurrentArea.GetTraversalPoints(TraversalComp.Method, TraversalPoints);
		for (UTraversalScenepointComponent Pt : TraversalPoints)
		{
			UArcTraversalScenepoint Point = Cast<UArcTraversalScenepoint>(Pt);
			if (Point == nullptr)
				continue;

			// Skip points where we need to move past target
			if (ToTarget.DotProduct(TargetLoc - Point.WorldLocation) < 0.0)
				continue;

			for (int iDest = 0; iDest < Point.GetDestinationCount(); iDest++)
			{
				ATraversalAreaActor DestArea = Cast<ATraversalAreaActor>(Point.GetDestinationArea(iDest));
				if(DestArea != nullptr && DestArea.GetInvalidDestination())
					continue;

				// Do not use points already in use by others or where team mates are near
				FVector DestLoc = Point.GetDestination(iDest);
				if (!DestArea.CanUseLandingAt(Owner, DestLoc))
					continue;
				if (IsCrowded(DestLoc))
					continue;

				// Transit areas and points where we have to pass beyond the target 
				// will only be considered if there are no better points.
				FVector DestToTarget = TargetLoc - DestLoc;
				float DistSqr = DestToTarget.SizeSquared();
				bool bGoodPoint = (DestToTarget.DotProduct(ToTarget) > 0.0);
				if (bGoodPoint)
				{
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
			LaunchPoint.GetTraversalArc(Destination, TraversalArc);

		// Assume we can traverse directly from current location
		TraversalArc.LaunchLocation = Owner.ActorLocation;

		bTraversing = true;

		StartLocation = Owner.ActorLocation;
		if (LaunchPoint != nullptr)
			DestinationArea = Cast<ATraversalAreaActor>(LaunchPoint.GetDestinationArea(Destination));
		if (DestinationArea != nullptr)
		{
			DestinationPoint = DestinationArea.GetAnyClosestTraversalPoint(TraversalArc.LandLocation);
			if (!DestinationPoint.WorldLocation.IsWithinDist(TraversalArc.LandLocation, 100.0))
				DestinationPoint = nullptr; // We don't really know which point we'll land by
		}

		if (DestinationPoint != nullptr)
			DestinationPoint.Use(Owner);

		if(HasControl())
			CrumbInitialize(LaunchPoint, TraversalArc, DestinationArea, DestinationPoint);
	}
	
	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		Super::OnDeactivated();
		if (JetpackComp.IsUsingJetpack())
		{
			UEnforcerJetpackEffectHandler::Trigger_JetpackEnd(Owner);
			JetpackComp.StopJetpack();
		}
		Cooldown.Set(5.0);

		// If we've started traversing but haven't reached destination, we no longer know which traversal area we're in
		if(bTraversing && LaunchPoint != nullptr && TraversalComp.CurrentArea != LaunchPoint.GetDestinationArea(Destination))
			TraversalComp.SetCurrentArea(nullptr);

		if (DestinationPoint != nullptr)
			DestinationPoint.Release(Owner);

		GentComp.ReleaseToken(n"TraversalChase", this, 2);
		GlobalGentComp.ReleaseToken(n"GlobalTraversalChase", this);
	}
	
	UFUNCTION(CrumbFunction)
	private void CrumbInitialize(UArcTraversalScenepoint _LaunchPoint, FTraversalArc _TraversalArc, ATraversalAreaActor _DestinationArea, UScenepointComponent _DestinationPoint)
	{
		bHasInitialized = true;
		LaunchPoint = _LaunchPoint;
		TraversalArc = _TraversalArc;
		DestinationArea = _DestinationArea;
		DestinationPoint = _DestinationPoint;
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if(!bHasInitialized)
			return;

		if (LaunchPoint == nullptr)
		{
			// Try again later
			DeactivateBehaviour();
			return;			
		}

		if(!bStartedJetpack)
		{
			bStartedJetpack = true;
			JetpackComp.StartJetpack();
			UEnforcerJetpackEffectHandler::Trigger_JetpackStart(Owner);
		}

		DestinationComp.RotateTowards(Target); 

		if (!TraversalComp.IsAtDestination(TraversalArc.LandLocation))
		{
			// Traversing to destination
			float SlowdownDistance = 1000;
			float StartDistance = StartLocation.Distance(Owner.ActorLocation);
			float EndDistance = TraversalArc.LandLocation.Distance(Owner.ActorLocation);
			float SpeedFraction = 1;
			if(EndDistance < SlowdownDistance)
				SpeedFraction = Math::Clamp(EndDistance / SlowdownDistance, 0.1, 1);
			else if(StartDistance < SlowdownDistance)
				SpeedFraction = Math::Clamp(StartDistance / SlowdownDistance, 0.5, 1);
			TraversalComp.Traverse(TraversalArc, TraversalSettings.ChaseSpeed * SpeedFraction);

			// Traverse anim until close, then landing
			if ((JetpackComp.AnimArcAlpha > 0.5) && (Owner.ActorLocation.IsWithinDist(TraversalArc.LandLocation, 57.0)))
				AnimComp.RequestFeature(LocomotionFeatureAISkylineTags::JetpackTraverse, SubTagAIJetpackTraverse::Land, EBasicBehaviourPriority::Medium, this);
			else		
				AnimComp.RequestFeature(LocomotionFeatureAISkylineTags::JetpackTraverse, EBasicBehaviourPriority::Medium, this);
		}
		else if (ActiveDuration < LandingTime)
		{
			// We're there!
			TraversalComp.SetCurrentArea(DestinationArea);
			LandingTime = ActiveDuration;
		
			UEnforcerJetpackEffectHandler::Trigger_JetpackEnd(Owner);
			AnimComp.RequestFeature(LocomotionFeatureAISkylineTags::JetpackTraverse, SubTagAIJetpackTraverse::Land, EBasicBehaviourPriority::Medium, this);
			JetpackComp.StopJetpack();
		}
		else if (ActiveDuration > LandingTime + 0.8)
		{
			// Short landing pause
			if ((TraversalComp.CurrentArea != nullptr) && TraversalComp.CurrentArea.bTransitArea)
				Cooldown.Set(0.0);
			else
				Cooldown.Set(1.0);
		}
#if EDITOR
		if (Owner.bHazeEditorOnlyDebugBool)
		{
			if (DestinationPoint != nullptr)
				Debug::DrawDebugLine(Owner.FocusLocation, DestinationPoint.WorldLocation, DestinationPoint.CanUse(Owner) ? FLinearColor::Green : FLinearColor::Red, 10);

		}
#endif
	}

	bool IsCrowded(FVector Location)
	{
		if (!IsValid(BehaviourComp.Team))
			return false;
		for (AHazeActor TeamMate : BehaviourComp.Team.GetMembers())
		{
			if (TeamMate == nullptr)
				continue;
			if (TeamMate.ActorLocation.IsWithinDist(Location, 80.0))
				return true;
		}
		for (AEnforcerGrenade Grenade : TListedActors<AEnforcerGrenade>())
		{
			if (!Grenade.bLanded)
				continue;
			if (Grenade.bExploded)
				continue;
			if (Grenade.ActorLocation.IsWithinDist(Location, 500.0))
				return true; // Crowded by explosive potential
		}
		return false;
	}
}