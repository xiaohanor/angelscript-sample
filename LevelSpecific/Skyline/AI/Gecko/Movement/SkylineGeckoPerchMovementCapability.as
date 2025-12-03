struct FGeckoPerchParams
{
	bool bJump = false;
	FVector LandLocation;
}

class USkylineGeckoPerchMovementCapability : UHazeCapability
{	
	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;

	default CapabilityTags.Add(CapabilityTags::Movement);
	
	default TickGroup = EHazeTickGroup::ActionMovement;
	default TickGroupOrder = 95;

	default DebugCategory = CapabilityTags::Movement;

	UBasicAICharacterMovementComponent MoveComp;
	UBasicAIDestinationComponent DestinationComp;
	UHazeCrumbSyncedActorPositionComponent CrumbMotionComp;
	UBasicAIAnimationComponent AnimComp;
	USkylineGeckoComponent GeckoComp;

	USkylineGeckoSettings Settings;

	// Allow clipping through geometry to get where we want to go. This should be subtle, as we mostly have some invisible collision in nightclub
	UTeleportingMovementData Movement;

	ASkylineTorCenterPoint Arena;

	FVector PrevLocation;
	FHazeAcceleratedRotator AccUp;

	bool bJumpingToArena;
	bool bHasLandedOnEntry = false;
	FVector LandLocation;

	FVector CurveStart;
	float CurveApexFraction;
	float CurveAlpha;
	float CurveAlphaPerSecond;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		DestinationComp = UBasicAIDestinationComponent::GetOrCreate(Owner);
		CrumbMotionComp = UHazeCrumbSyncedActorPositionComponent::GetOrCreate(Owner); // This has to be created before MoveComp runs BeginPlay
		MoveComp = UBasicAICharacterMovementComponent::GetOrCreate(Owner);
		GeckoComp = USkylineGeckoComponent::Get(Owner);
		AnimComp = UBasicAIAnimationComponent::GetOrCreate(Owner);
		Settings = USkylineGeckoSettings::GetSettings(Owner);
		Arena = TListedActors<ASkylineTorCenterPoint>().GetSingle();
		Movement = MoveComp.SetupTeleportingMovementData();
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate(FGeckoPerchParams& OutParams) const
	{
		if (DestinationComp.bHasPerformedMovement)
			return false;
		if (GeckoComp.bIsLeaping.Get())
			return false;
		if (GeckoComp.bOverturned)
			return false;
		if (IsInsideArena())
			return false;

		// Should we jump immediately? Using params to skip one crumb message.
		if (WantsToReturnToArena())
		{
			OutParams.bJump = true;
			OutParams.LandLocation = GetLandLocation();
		} 
        return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (DestinationComp.bHasPerformedMovement)
			return true;
		if (GeckoComp.bOverturned)
			return true;
		if (bJumpingToArena && (CurveAlpha > 1.0 - SMALL_NUMBER))
			return true;
		return false;
	}

	bool IsInsideArena() const
	{
		if (Arena == nullptr)
			return true;

		FVector ArenaCenter = Arena.ActorLocation;
		if (!Math::IsWithin(Owner.ActorLocation.Z, ArenaCenter.Z - 20.0, ArenaCenter.Z + 500.0))
			return false;
		if (!Owner.ActorLocation.IsWithinDist2D(ArenaCenter, Arena.ArenaRadius + 20.0)) 
			return false;
		return true;
	}

	bool WantsToReturnToArena() const
	{
		return DestinationComp.HasDestination();	
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FGeckoPerchParams Params)
	{
		MoveComp.AccRotation.SnapTo(Owner.ActorRotation);
		PrevLocation = Owner.ActorLocation;
		AccUp.SnapTo(MoveComp.WorldUp.Rotation());

		bJumpingToArena = false;
		CurveAlpha = 0.0;
		if (Params.bJump)
			StartJumpToArena(Params.LandLocation);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		GeckoComp.bIsLeaping.Clear(this);
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
			Movement.ApplyCrumbSyncedGroundMovementWithCustomVelocity(Velocity);			
		}

		PrevLocation = Owner.ActorLocation;
		MoveComp.ApplyMoveAndRequestLocomotion(Movement, AnimComp.FeatureTag);
		DestinationComp.bHasPerformedMovement = true;

		if(!bHasLandedOnEntry && Owner.ActorLocation.IsWithinDist(LandLocation, 200))
		{
			USkylineGeckoEffectHandler::Trigger_OnEntryLand(Owner);
			bHasLandedOnEntry = true;
		}
	}

	FVector GetTargetUp()
	{
		if (bJumpingToArena)
			return FVector::UpVector;
		return MoveComp.WorldUp;
	}

	void ComposeMovement(float DeltaTime)
	{	
		if (!bJumpingToArena)
			Perch(DeltaTime);
		else 
			JumpToArena(DeltaTime);
	}

	void Perch(float DeltaTime)
	{
		if (WantsToReturnToArena())
			CrumbStartJumpToArena(GetLandLocation());

		// Just remain in place	until it's time to jump

		// Align actor up vector with movement up if necessary
		if (MoveComp.WorldUp.DotProduct(Owner.ActorUpVector) < 0.99)
			MoveComp.RotateTowardsDirection(Owner.ActorForwardVector, Settings.TurnDuration, DeltaTime, Movement);
	}

	UFUNCTION(CrumbFunction)
	void CrumbStartJumpToArena(FVector LandLoc)
	{
		StartJumpToArena(LandLoc);
	}

	private void StartJumpToArena(FVector LandLoc)
	{
		bJumpingToArena = true;
		GeckoComp.bIsLeaping.Apply(true, this);
		GeckoComp.CurrentClimbSpline = nullptr;
		CurveStart = Owner.ActorLocation;
		CurveAlpha = 0.0;
		CurveApexFraction = 0.4; // TODO: Calculate this properly
		LandLocation = LandLoc;
		CurveAlphaPerSecond = Settings.JumpFromPerchSpeed / Math::Max(1.0, CurveStart.Distance(LandLocation));
		
		AnimComp.RequestFeature(FeatureTagGecko::Jump, EBasicBehaviourPriority::Medium, this);
	}

	void JumpToArena(float DeltaTime)
	{
		CurveAlpha = Math::Min(1.0, CurveAlpha + CurveAlphaPerSecond * DeltaTime);

		FVector CurveControl = CurveStart * (1.0 - CurveApexFraction) + LandLocation * CurveApexFraction;
		CurveControl.Z = CurveStart.Z + CurveStart.Distance(LandLocation) * 0.4; // TODO: Calculate this properly
		FVector NewLoc = BezierCurve::GetLocation_1CP(CurveStart, CurveControl, LandLocation, CurveAlpha);
		Movement.AddDeltaFromMoveToPositionWithCustomVelocity(NewLoc, (NewLoc - Owner.ActorLocation) / DeltaTime);

		// Match direction with jump
		MoveComp.RotateTowardsDirection(LandLocation - CurveStart, Settings.TurnDuration, DeltaTime, Movement, true);

#if EDITOR
		if (Owner.bHazeEditorOnlyDebugBool)
			BezierCurve::DebugDraw_1CP(CurveStart, CurveControl, LandLocation, FLinearColor::Yellow, 5.0);
#endif
	}

	FVector GetLandLocation() const
	{
		// Land on navmesh, in direction of destination if any.
		FVector Dest = DestinationComp.Destination;
		FVector OwnLoc = Owner.ActorLocation;
		if (!DestinationComp.HasDestination())
		{
			Dest = OwnLoc;
			// if (DestinationComp.FollowSplinePosition.CurrentSpline != nullptr)
			// 	Dest += DestinationComp.FollowSplinePosition.WorldUpVector * Settings.ClimbChaseSplineRange * 0.5;
			// else
				Dest += Owner.ActorForwardVector * Settings.ClimbChaseSplineRange * 0.5;
		}
		Dest.Z = Arena.ActorLocation.Z;

		float WithinRadius = Arena.ArenaRadius - 100.0;
		if (!Dest.IsWithinDist2D(Arena.ActorLocation, WithinRadius))
			Dest = Arena.ActorLocation + (Dest - Arena.ActorLocation).GetSafeNormal2D() * WithinRadius;
		
		// Jump to somewhat within the closest edge of arena in the direction of the destination
		FVector Start = OwnLoc;
		Start.Z = Dest.Z;
		FLineSphereIntersection Intersects = Math::GetLineSegmentSphereIntersectionPoints(Start, Dest, Arena.ActorLocation, WithinRadius + 1.0);
		if (!Intersects.bHasIntersection)
			return Arena.ActorLocation + (Start - Arena.ActorLocation).GetSafeNormal2D() * Arena.ArenaRadius * 0.3; // Something went wrong, use a backup location near the center of the arena.

		FVector ArenaLoc = Intersects.MinIntersection + (Dest - Intersects.MinIntersection) * Math::RandRange(0.0, 0.4);		
		FVector PathLoc;
		if (!Pathfinding::FindNavmeshLocation(ArenaLoc, 40.0, 600.0, PathLoc))
			return Arena.ActorLocation + (Start - Arena.ActorLocation).GetSafeNormal2D() * Arena.ArenaRadius * 0.3; // Something went wrong, use a backup location near the center of the arena.

		return PathLoc;
	}
}
