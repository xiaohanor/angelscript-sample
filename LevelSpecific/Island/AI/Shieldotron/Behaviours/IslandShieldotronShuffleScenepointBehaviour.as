class UIslandShieldotronShuffleScenepointBehaviour : UBasicBehaviour
{	
	// Movement only (which is replicated separately)
	default CompoundNetworkSupport = EHazeCompoundNetworkSupport::ActivatesOnControlOnly;

	default Requirements.Add(EBasicBehaviourRequirement::Movement);

	UBasicAIHealthComponent HealthComp;
	AIslandShieldotronShuffleScenepointActor ShufflePoint;
	UIslandShieldotronScenepointComponent ShufflePointComp;
	UIslandShieldotronJumpComponent JumpComp;
	UIslandShieldotronSettings Settings;
	FVector Destination;
	
	float NextCheckSwitchShufflePointTime;
	TArray<AIslandShieldotronShuffleScenepointActor> ReachableShufflePoints;
	

	UTraversalComponentBase TraversalComp;
	ATraversalAreaActorBase CurrentArea;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Super::Setup();
		Settings = UIslandShieldotronSettings::GetSettings(Owner);
		HealthComp = UBasicAIHealthComponent::Get(Owner);
		UHazeActorRespawnableComponent::Get(Owner).OnPostRespawn.AddUFunction(this, n"OnRespawn");
		TraversalComp = UTraversalComponentBase::Get(Owner);
		JumpComp = UIslandShieldotronJumpComponent::Get(Owner);
	}

	UFUNCTION()
	private void OnRespawn()
	{
	}

	UFUNCTION(BlueprintOverride)
	void PreTick(float DeltaTime)
	{
		if (!Settings.bUseShuffleScenepoints)
			return;
		if (ShufflePoint != nullptr)
			return;
		if (JumpComp.bIsJumping)
			return;
		if (!Requirements.CanClaim(BehaviourComp, this))
			return; // Still doing entrance behaviours etc
		if (NextCheckSwitchShufflePointTime > Time::GetGameTimeSeconds())
			return;

		NextCheckSwitchShufflePointTime += 0.25;
		
		// Update list of reachable areas if using traversal areas.
		if (TraversalComp != nullptr && TraversalComp.CurrentArea != nullptr)
		{
			// Has Current Area changed?
			if (CurrentArea == nullptr || CurrentArea != TraversalComp.CurrentArea)
			{
				ShufflePoint = nullptr; // Current shuffle point is not in the current area, find a new one.
				CurrentArea = TraversalComp.CurrentArea;
				UpdateReachableShufflePointsList();
			}
		}
		else if (ReachableShufflePoints.IsEmpty())
		{
			// Consider all ShufflePoints as reachable. Except distant points.
			TListedActors<AIslandShieldotronShuffleScenepointActor> ShufflePoints;
			for (AIslandShieldotronShuffleScenepointActor Point : ShufflePoints)
			{
				// Skip far away points
				if (Point.GetSquaredDistanceTo(Owner) > 10000*10000)
					continue;
				ReachableShufflePoints.Add(Point);
			}
		}
		
		// Try find closest point
		AIslandShieldotronShuffleScenepointActor ClosestPoint;
		bool bHasPoint = GetClosestReachableShufflePoint(ClosestPoint);
		if (bHasPoint && ShufflePoint != ClosestPoint)
		{
			ShufflePoint = ClosestPoint;
			ShufflePointComp = ShufflePoint.GetScenepoint();
			Destination = Owner.ActorLocation;
		}
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (!Super::ShouldActivate())
			return false;
		if (ShufflePoint == nullptr)
			return false;
		if (!TargetComp.HasValidTarget())
			return false;
		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (Super::ShouldDeactivate())
			return true;
		if (ShufflePoint == nullptr)
			return true;
		if (JumpComp.bIsJumping)
			return true;
		if (!Settings.bUseShuffleScenepoints)
			return true;
		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		Super::OnActivated();
		
		Owner.BlockCapabilities(n"MortarAttack", this);

		if (ShufflePoint.bRequirePathFindingCheck && !Pathfinding::HasPath(Owner.ActorLocation, ShufflePoint.ActorLocation))
		{
			ReachableShufflePoints.RemoveSwap(ShufflePoint);
			ShufflePoint = nullptr;
			DeactivateBehaviour();
			return;
		}
		// Try to find a not too nearby destination point
		for (int Tries = 10; Tries >= 0; Tries--)
		{
			Destination = ShufflePoint.GetDestinationPoint();
			if (!Owner.ActorLocation.IsWithinDist(Destination, ShufflePointComp.MovementMinDistance)) // if outside of min distance
				break;
		}
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		Super::OnDeactivated();
		ShufflePoint = nullptr;
		Cooldown.Set(Math::RandRange(ShufflePointComp.NextMoveCooldownRangeMin, ShufflePointComp.NextMoveCooldownRangeMax));
		Owner.UnblockCapabilities(n"MortarAttack", this);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		// Try holding the shuffle point
		if (ShufflePoint == nullptr || !ShufflePoint.Hold(Owner, 2500.0))
		{
			DeactivateBehaviour();
			return;
		}		

		// Try moving towards destination
		Destination.Z = Owner.ActorLocation.Z;
		if (!Owner.ActorLocation.IsWithinDist(Destination, 50.0) &&
			 ActiveDuration < ShufflePointComp.MovementMaxDuration)
		{
			DestinationComp.MoveTowardsIgnorePathfinding(Destination, Settings.ShufflePointMoveSpeed * ShufflePointComp.MovementSpeedFactor);
		}
		else
		{
			DeactivateBehaviour();
		}

#if EDITOR
		//Owner.bHazeEditorOnlyDebugBool = true;
		if (Owner.bHazeEditorOnlyDebugBool)
		{
			// Draw current destination
			Debug::DrawDebugSphere(Destination, 50, 12, FLinearColor::Blue, 10, Duration = 0.5);
			Debug::DrawDebugLine(Owner.ActorCenterLocation, Destination, FLinearColor::Green);
			// Draw a line to current shuffle point
			Debug::DrawDebugLine(Owner.ActorCenterLocation, ShufflePoint.ActorLocation, FLinearColor::Blue);
		}
#endif

#if !RELEASE
		FTemporalLog TemporalLog = TEMPORAL_LOG(this);
		TemporalLog.Sphere("OwnLoc", Owner.ActorLocation, 50, FLinearColor::LucBlue);
		TemporalLog.Sphere("Destination", Destination, 50, FLinearColor::Green);
		TemporalLog.Value("HasDestination", DestinationComp.HasDestination());
#endif
		
	}

	// Call when current TraversalArea has changed.
	private void UpdateReachableShufflePointsList()
	{
		ReachableShufflePoints.Empty();
				
		TListedActors<AIslandShieldotronShuffleScenepointActor> ShufflePoints;
		for (AIslandShieldotronShuffleScenepointActor Point : ShufflePoints)
		{
			if (CurrentArea != Point.ParentArea)
				continue;

			// Skip far away points
			if (Point.GetSquaredDistanceTo(Owner) > 10000*10000)
				continue;
			
			ReachableShufflePoints.Add(Point);
		}	
	}

	// Closest to boundary of shape or within a shape.
	// Currently doesn't prefer one shape over the other if shapes are overlaping.
	private bool GetClosestReachableShufflePoint(AIslandShieldotronShuffleScenepointActor& OutClosestPoint)
	{
		bool bHasPoint = false;
		float BestDistSquared = MAX_flt;

		if (ShufflePoint != nullptr)
			BestDistSquared = ShufflePoint.GetDist2DToShape(Owner.ActorLocation);
		for (AIslandShieldotronShuffleScenepointActor Point : ReachableShufflePoints)
		{
			// Check if can use point.
			if (!Point.IsValidHolder(Owner, 2500.0))
				continue;

			float DistSquared = Point.GetDist2DToShape(Owner.ActorLocation);
			if (DistSquared < BestDistSquared)
			{
				bHasPoint = true;
				OutClosestPoint = Point;
				BestDistSquared = DistSquared;
			}
		}
		return bHasPoint;
	}
}


