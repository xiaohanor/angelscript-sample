struct FGeckoSplineEntryParams
{
	ASkylineGeckoEntrySplineActor Spline;
}

class USkylineGeckoSplineEntryBehaviour : UBasicBehaviour
{
	default Requirements.Add(EBasicBehaviourRequirement::Movement);
	default Requirements.Add(EBasicBehaviourRequirement::Focus);

	USkylineGeckoComponent GeckoComp;
	UGravityBladeGrappleComponent GravityBladeGrappleComp;
	USkylineGeckoSettings Settings;

	TArray<ASkylineGeckoEntrySplineActor> EntrySplines;
	ASkylineGeckoEntrySplineActor EntrySpline;
	bool bEntryComplete = false;
	float Speed;
	bool bReachedSplineEnd;
	float LeaveSplineTime;
	bool bLeapingToDestination;
	FVector Destination;
	FSplinePosition SplineDestination;
	float SideOffset;
	bool bBlockedMovement = false;
	FTimerHandle PostSpawnTimer;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Super::Setup();
		GeckoComp = USkylineGeckoComponent::GetOrCreate(Owner);
		GravityBladeGrappleComp = UGravityBladeGrappleComponent::GetOrCreate(Owner);
		Settings = USkylineGeckoSettings::GetSettings(Owner);

		TArray<ASkylineGeckoEntrySplineActor> AllEntrySplines = TListedActors<ASkylineGeckoEntrySplineActor>().GetArray();
		for(ASkylineGeckoEntrySplineActor Spline : AllEntrySplines)
		{
			if(!Spline.bDisabled)
				EntrySplines.Add(Spline);
		}
		EntrySplines.Shuffle();

		auto RespawnComp = UHazeActorRespawnableComponent::Get(Owner);
		RespawnComp.OnRespawn.AddUFunction(this, n"OnRespawn");
	}

	UFUNCTION()
	private void OnRespawn()
	{
		bEntryComplete = false;
		if (EntrySplines.Num() == 0)
			return; // We're not using spline entry

		Owner.AddActorVisualsBlock(this);

		// Block movement until we've decided which spline to enter through, to avoid unnecessary net messages
		if (!bBlockedMovement)
			Owner.BlockCapabilities(CapabilityTags::Movement, this);
		bBlockedMovement = true;
	}

	ASkylineGeckoEntrySplineActor FindEntrySpline() const
	{
		if (EntrySplines.Num() == 0)
			return nullptr;

		// Use the first spline which has been used the fewest amount of times. 
		// List will be shuffled to ensure randomness between equally used splines.
		ASkylineGeckoEntrySplineActor BestSpline = EntrySplines[0];
		for (int i = 1; i < EntrySplines.Num(); i++)
		{
			if (EntrySplines[i].bLastUsedSpline)
				continue;
			if (EntrySplines[i].NumUsages < BestSpline.NumUsages)
				BestSpline = EntrySplines[i];
		}
		return BestSpline;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate(FGeckoSplineEntryParams& OutParams) const
	{
		if (!Super::ShouldActivate())
			return false;
		if (bEntryComplete)
			return false;
		ASkylineGeckoEntrySplineActor Spline = FindEntrySpline();
		if (Spline == nullptr)
			return false;
		OutParams.Spline = Spline;
		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (Super::ShouldDeactivate())
			return true;
		if (bEntryComplete)
			return true;
		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FGeckoSplineEntryParams Params)
	{
		Super::OnActivated();

		// Entry time! Show ourselves and allow movement
		Owner.RemoveActorVisualsBlock(this);
		if (bBlockedMovement)
			Owner.UnblockCapabilities(CapabilityTags::Movement, this);
		bBlockedMovement = false;

		// We shuffle the list after each use to ensure random usage order and 
		// mark this spline as the last used so we never use one twice in a row
		EntrySpline = Params.Spline;
		EntrySpline.NumUsages++;
		EntrySplines.Shuffle();
		for (ASkylineGeckoEntrySplineActor Spline : EntrySplines)
		{
			Spline.bLastUsedSpline = false;
		}
		EntrySpline.bLastUsedSpline = true;

		FSplinePosition SplinePos = EntrySpline.Spline.GetSplinePositionAtSplineDistance(0.0);
		Owner.TeleportActor(SplinePos.WorldLocation, SplinePos.WorldRotation.Rotator(), this);
		DestinationComp.FollowSplinePosition = SplinePos;

		Speed = Settings.SplineEntrySpeed;
		if (EntrySpline.bUseCustomSpeed)
			Speed = EntrySpline.CustomSpeed;

		GeckoComp.bAllowBladeHits.Apply(false, this);

		bReachedSplineEnd = false;
		bEntryComplete = false;
		LeaveSplineTime = BIG_NUMBER;
	 	bLeapingToDestination = false;
		GeckoComp.ClimbSplineSideOffset = 0.0;

		SideOffset = 40.0 * Math::RandRange(-1.0, 1.0);	

		GravityBladeGrappleComp.Disable(this);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		Super::OnDeactivated();
		GeckoComp.bAllowBladeHits.Clear(this);
		bEntryComplete = true;
		GeckoComp.bShouldLeap.Clear(this);
		GravityBladeGrappleComp.Enable(this);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{	
		if (!bReachedSplineEnd)
		{
			// Run along spline
			DestinationComp.MoveAlongSpline(EntrySpline.Spline, Speed);

			// Spread out at end of spline (TODO: Use spline width for better control)
			if (DestinationComp.FollowSplinePosition.CurrentSpline == EntrySpline.Spline)
				GeckoComp.ClimbSplineSideOffset = SideOffset * Math::Square((DestinationComp.FollowSplinePosition.CurrentSplineDistance / Math::Max(EntrySpline.Spline.SplineLength, 1.0)));
			
			if (HasControl() && !bReachedSplineEnd && DestinationComp.IsAtSplineEnd(EntrySpline.Spline, 20.0))
				CrumbReachSplineEnd();
		}
		else if (!bLeapingToDestination)
		{
			// Stop at spline end
			DestinationComp.MoveAlongSpline(EntrySpline.Spline, 0.0);
			if (HasControl() && (ActiveDuration > LeaveSplineTime))
				CrumbLeapToDestination();
		}
		else if (SplineDestination.IsValid()) 
		{
			// Leaping to destination spline
			bool bFwdAlign = (Owner.ActorForwardVector.DotProduct(SplineDestination.WorldForwardVector) > 0.0);
			DestinationComp.MoveAlongSpline(SplineDestination.CurrentSpline, Settings.JumpFromPerchSpeed, bFwdAlign);
		}
		else
		{
			// Leaping towards destination (we're not expected to actually reach destination, but should land on navmesh near it)
			DestinationComp.MoveTowardsIgnorePathfinding(Destination, Settings.JumpFromPerchSpeed);
		} 

		// Check if we've completed leap to destination and thus are done
		if (bLeapingToDestination && (ActiveDuration > LeaveSplineTime + 0.5) && !GeckoComp.bIsLeaping.Get())
			bEntryComplete = true; 
	}

	UFUNCTION(CrumbFunction)
	void CrumbReachSplineEnd()
	{
		bReachedSplineEnd = true;
		AnimComp.RequestFeature(FeatureTagGecko::Taunts, SubTagGeckoTaunts::EntryBeforeJump, EBasicBehaviourPriority::Medium, this);
		LeaveSplineTime = ActiveDuration + 1.0;
	}

	UFUNCTION(CrumbFunction)
	void CrumbLeapToDestination()
	{
		bLeapingToDestination = true;
		AnimComp.RequestFeature(FeatureTagGecko::Jump, EBasicBehaviourPriority::Medium, this);

		UHazeSplineComponent DestSpline = UHazeSplineComponent::Get(EntrySpline.Destination);
		if (DestSpline != nullptr)
		{
			// Leap to a spline
			SplineDestination = DestSpline.GetClosestSplinePositionToWorldLocation(Owner.ActorLocation);
			DestinationComp.FollowSplinePosition = SplineDestination;
		}
		else
		{
			// Leap to the location of an actor
			SplineDestination = FSplinePosition();
			Destination = EntrySpline.Destination.ActorLocation;
		}
	}
}
