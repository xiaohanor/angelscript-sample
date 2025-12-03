struct FGeckoClimbSplineMovementParams
{
	FSplinePosition StartPosition;
	bool bAtSpline = false;
}

class USkylineGeckoClimbSplineMovementCapability : UHazeCapability
{	
	default CapabilityTags.Add(CapabilityTags::Movement);
	default CapabilityTags.Add(n"WallclimbingMovement");	

	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;

	default TickGroup = EHazeTickGroup::ActionMovement;
	default TickGroupOrder = 90; 
	default DebugCategory = CapabilityTags::Movement;

	UBasicAICharacterMovementComponent MoveComp;
	UBasicAIDestinationComponent DestinationComp;
	UHazeCrumbSyncedActorPositionComponent CrumbMotionComp;
	USkylineGeckoComponent GeckoComp;
	UBasicAIAnimationComponent AnimComp;
	UPathfollowingMoveToComponent MoveToComp;

	UHazeSplineComponent CurrentSpline;

	UPathfollowingSettings PathingSettings;
	USkylineGeckoSettings Settings;
	FHazeAcceleratedRotator AccUp;

	// Invisible wall at nightclub railing so ignore collision. 
	// This is fine since as long as spline is properly placed
	// though we may clip through stuff when jumping to spline. 
	UTeleportingMovementData Movement; 

	FVector PrevLocation;

	FVector CurveStart;
	float CurveApexFraction;
	float CurveAlpha;
	float CurveAlphaPerSecond;
	bool bLeaveSpline;

	FHazeAcceleratedFloat Speed;
	FHazeAcceleratedFloat AccSideOffset;

	float ReturnTime;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		DestinationComp = UBasicAIDestinationComponent::Get(Owner);
		CrumbMotionComp = UHazeCrumbSyncedActorPositionComponent::Get(Owner); // This has to be created before MoveComp runs BeginPlay
		MoveComp = UBasicAICharacterMovementComponent::Get(Owner);
		GeckoComp = USkylineGeckoComponent::Get(Owner);
		AnimComp = UBasicAIAnimationComponent::Get(Owner);
		Movement = MoveComp.SetupTeleportingMovementData();
		MoveToComp = UPathfollowingMoveToComponent::Get(Owner);
		PathingSettings = UPathfollowingSettings::GetSettings(Owner);
		Settings = USkylineGeckoSettings::GetSettings(Owner);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate(FGeckoClimbSplineMovementParams& OutParams) const
	{
		if (DestinationComp.bHasPerformedMovement)
			return false;
		if (DestinationComp.FollowSpline == nullptr)
			return false;

		// If followsplineposition is set to spline we want to follow, we assume this is the position we should jump to
		if (DestinationComp.FollowSplinePosition.CurrentSpline == DestinationComp.FollowSpline)
			OutParams.StartPosition = DestinationComp.FollowSplinePosition;
		else 
			OutParams.StartPosition = DestinationComp.FollowSpline.GetClosestSplinePositionToWorldLocation(Owner.ActorLocation); // Spline not set, jump to nearest location

		if ((GeckoComp.CurrentClimbSpline != nullptr) && (GeckoComp.CurrentClimbSpline == DestinationComp.FollowSpline))
			OutParams.bAtSpline = true;
		else if (OutParams.StartPosition.WorldLocation.IsWithinDist(Owner.ActorLocation, 20.0))
			OutParams.bAtSpline = true;

	    return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (DestinationComp.bHasPerformedMovement)
			return true;
		if (ActiveDuration > ReturnTime)
			return true;
		if ((DestinationComp.FollowSpline != nullptr) && (DestinationComp.FollowSpline != CurrentSpline))
			return true; // We want to change spline, deactivate and reactivate
        return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FGeckoClimbSplineMovementParams Params)
	{
		DestinationComp.FollowSplinePosition = Params.StartPosition;
		CurrentSpline = Params.StartPosition.CurrentSpline;

		MoveComp.AccRotation.SnapTo(Owner.ActorRotation);
		PrevLocation = Owner.ActorLocation;
		AccUp.SnapTo(MoveComp.WorldUp.Rotation());
		CurveStart = Owner.ActorLocation;
		Speed.SnapTo(0.0);

		if (Params.bAtSpline)
		{
			// Already climbing along spline
			CurveAlpha = 1.0;
			AccSideOffset.SnapTo(DestinationComp.FollowSplinePosition.WorldRightVector.DotProduct(Owner.ActorLocation - DestinationComp.FollowSplinePosition.WorldLocation));
			// TODO: We can currently snap into position here, smooth out if necessary
		}
		else
		{
			// Set up curve to jump to spline
			CurveAlpha = 0.0;
			CurveStart = Owner.ActorLocation;
			CurveApexFraction = 0.6; // TODO: Calculate this properly
			CurveAlphaPerSecond = Settings.JumpToSplineSpeed / Math::Max(1.0, CurveStart.Distance(DestinationComp.FollowSplinePosition.WorldLocation));
			AnimComp.RequestFeature(FeatureTagGecko::Jump, EBasicBehaviourPriority::Medium, this);
			AccSideOffset.SnapTo(0.0);
		}
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		// No longer running along spline
		GeckoComp.CurrentClimbSpline = nullptr;
		AnimComp.ClearFeature(this);
		GeckoComp.bIsLeaping.Clear(this);
		MoveToComp.ResetPath();
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if(!MoveComp.PrepareMove(Movement, AccUp.AccelerateTo(GetTargetUp().Rotation(), 1.0, DeltaTime).Vector()))
			return;

		if(HasControl())
		{
			ComposeMovement(DeltaTime);
		}
		else
		{
			// Since we normally don't want to replicate velocity, we use move since last frame instead.
			// This can fluctuate wildly, introduce smoothing/velocity replication if necessary
			FVector Velocity = (DeltaTime > 0.0) ? (Owner.ActorLocation - PrevLocation) / DeltaTime : Owner.ActorVelocity;
			Movement.ApplyCrumbSyncedAirMovementWithCustomVelocity(Velocity);
			PrevLocation = Owner.ActorLocation;
			
			// Update curve alpha to get proper world up. It's fine if this desyncs some from crumb trail.
			CurveAlpha = Math::Min(1.0, CurveAlpha + CurveAlphaPerSecond * DeltaTime);  
		}

		MoveComp.ApplyMove(Movement);
		DestinationComp.bHasPerformedMovement = true;
	}

	FVector GetTargetUp()
	{
		if (CurveAlpha < 1.0)
		{
			// Jumping to spline
			FQuat SplineUp = DestinationComp.FollowSplinePosition.WorldUpVector.ToOrientationQuat();
			return FQuat::Slerp(FVector::UpVector.ToOrientationQuat(), SplineUp, Math::Max(1.0, CurveAlpha * 4.0)).UpVector;
		}

		// Following spline
		return DestinationComp.FollowSplinePosition.WorldUpVector;
	}

	void ComposeMovement(float DeltaTime)
	{	
		if (DeltaTime < SMALL_NUMBER)
			return;

		if (CurveAlpha < 1.0)
			JumpToSpline(DeltaTime);
		else
			ClimbAlongSpline(DeltaTime);
	}

	void JumpToSpline(float DeltaTime)
	{
		GeckoComp.bIsLeaping.Apply(true, this);

		CurveAlpha = Math::Min(1.0, CurveAlpha + CurveAlphaPerSecond * DeltaTime);
		FVector CurveEnd = DestinationComp.FollowSplinePosition.WorldLocation;			
		FVector CurveControl = CurveStart * (1.0 - CurveApexFraction) + CurveEnd * CurveApexFraction;
		CurveControl.Z = CurveEnd.Z + CurveStart.Distance(CurveEnd) * 0.3; // TODO: Calculate this properly
		FVector NewLoc = BezierCurve::GetLocation_1CP(CurveStart, CurveControl, CurveEnd, CurveAlpha);
		Movement.AddDeltaFromMoveToPositionWithCustomVelocity(NewLoc, (NewLoc - Owner.ActorLocation) / DeltaTime);


		if (DestinationComp.Focus.IsValid())
		{
			// Look at focus
			MoveComp.RotateTowardsDirection(DestinationComp.Focus.GetFocusLocation() - Owner.FocusLocation, Settings.TurnDuration, DeltaTime, Movement);
		}
		else
		{
			// Match direction with landing position on spline
			float DirSign = (DestinationComp.bFollowSplineForwards ? 1.0 : -1.0);
			MoveComp.RotateTowardsDirection(DestinationComp.FollowSplinePosition.WorldForwardVector * DirSign, Settings.TurnDuration, DeltaTime, Movement, true);
		}
#if EDITOR
		if (Owner.bHazeEditorOnlyDebugBool)
			BezierCurve::DebugDraw_1CP(CurveStart, CurveControl, CurveEnd, FLinearColor::Yellow, 5.0);
#endif
	}

	void ClimbAlongSpline(float DeltaTime)
	{
		GeckoComp.bIsLeaping.Clear(this);
		AccSideOffset.AccelerateTo(GeckoComp.ClimbSplineSideOffset, 3.0, DeltaTime);

		if (DestinationComp.FollowSpline == nullptr)
		{
			// We no longer want to follow spline, start considering leaving it
			ReturnTime = Math::Min(ReturnTime, ActiveDuration + 0.5); 
		}
		else
		{
			// At spline, follow it
			ReturnTime = BIG_NUMBER;
			if ((GeckoComp.CurrentClimbSpline == nullptr) || (GeckoComp.CurrentClimbSpline != DestinationComp.FollowSpline))
				GeckoComp.CurrentClimbSpline = DestinationComp.FollowSpline;
		}

		float DirSign = (DestinationComp.bFollowSplineForwards ? 1.0 : -1.0);
		if (DestinationComp.Speed > 1.0)
			Speed.AccelerateTo(DestinationComp.Speed * DirSign, 2.0, DeltaTime); // Accelerate
		else
			Speed.AccelerateTo(0.0, 0.5, DeltaTime); // Quick brake
	
		DestinationComp.FollowSplinePosition.Move(Speed.Value * DeltaTime);
		FVector SplineLoc = DestinationComp.FollowSplinePosition.WorldLocation;
		SplineLoc += DestinationComp.FollowSplinePosition.WorldRightVector * AccSideOffset.Value;
		Movement.AddDeltaFromMoveToPositionWithCustomVelocity(SplineLoc, (DestinationComp.FollowSplinePosition.WorldLocation - Owner.ActorLocation) / DeltaTime);
		
		// Follow spline direction
		FVector TurnDir = DestinationComp.FollowSplinePosition.WorldForwardVector * DirSign;
		if ((DestinationComp.Speed < 1.0) && (Owner.ActorForwardVector.DotProduct(TurnDir) < 0.0))
			TurnDir = -TurnDir;
		MoveComp.RotateTowardsDirection(TurnDir, Settings.TurnDuration, DeltaTime, Movement, true);

		AnimComp.ClearFeature(this);

#if EDITOR
		if (Owner.bHazeEditorOnlyDebugBool)
			DestinationComp.FollowSplinePosition.CurrentSpline.DrawDebug(50, FLinearColor::Yellow, 5.0);
#endif
	}
}

