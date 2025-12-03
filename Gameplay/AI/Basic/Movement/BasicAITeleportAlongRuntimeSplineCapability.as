class UBasicAITeleportAlongRuntimeSplineCapabability : UHazeCapability
{
	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;

	default CapabilityTags.Add(CapabilityTags::Movement);
	default CapabilityTags.Add(n"SplineMovement");	
	default CapabilityTags.Add(n"DynamicSplineMovement");	

	default TickGroup = EHazeTickGroup::ActionMovement;
	default TickGroupOrder = 30; // Before regular movement
	default DebugCategory = CapabilityTags::Movement;

	UBasicAIRuntimeSplineComponent SplineComp;
	UBasicAICharacterMovementComponent MoveComp;
	UBasicAIDestinationComponent DestinationComp;
	UHazeCrumbSyncedActorPositionComponent CrumbMotionComp;
	UBasicAIAnimationComponent AnimComp;
	UTeleportingMovementData Movement;
	UBasicAIMovementSettings MoveSettings;

	FVector PrevLocation;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		SplineComp = UBasicAIRuntimeSplineComponent::GetOrCreate(Owner);		
		DestinationComp = UBasicAIDestinationComponent::GetOrCreate(Owner);
		CrumbMotionComp = UHazeCrumbSyncedActorPositionComponent::GetOrCreate(Owner); // This has to be created before MoveComp runs BeginPlay
		MoveComp = UBasicAICharacterMovementComponent::GetOrCreate(Owner);
		AnimComp = UBasicAIAnimationComponent::GetOrCreate(Owner);
		MoveSettings = UBasicAIMovementSettings::GetSettings(Owner);
		Movement = MoveComp.SetupTeleportingMovementData();
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (DestinationComp.bHasPerformedMovement)
			return false;
		if (!SplineComp.HasSpline())
			return false;
		if (SplineComp.IsNearEndOfSpline(0.1))
			return false;
		if (SplineComp.Speed == 0)
			return false;
		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (DestinationComp.bHasPerformedMovement)
			return true;
		if (!SplineComp.HasSpline())
			return true;
		if (SplineComp.IsNearEndOfSpline(0.09))
			return true;
		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		MoveComp.AccRotation.SnapTo(Owner.ActorRotation);
		PrevLocation = Owner.ActorLocation;
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		SplineComp.Reset();
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		// This is set in ResolveMovement, so will lag one frame behind
		if(!MoveComp.PrepareMove(Movement))
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
			Movement.ApplyCrumbSyncedAirMovementWithCustomVelocity(Velocity);;
			PrevLocation = Owner.ActorLocation;
		}

		MoveComp.ApplyMoveAndRequestLocomotion(Movement, AnimComp.FeatureTag);
		DestinationComp.bHasPerformedMovement = true;
	}

	void ComposeMovement(float DeltaTime)
	{	
		FVector OwnLoc = Owner.ActorLocation;
		FVector Velocity = MoveComp.Velocity;
		float Integratedfriction = Math::Exp(-MoveSettings.GroundFriction);

		// Move along spline 
		FHazeRuntimeSpline Spline = SplineComp.Spline;
		FVector SplineDir = Spline.GetDirectionAtDistance(SplineComp.DistanceAlongSpline).GetSafeNormal();
		float SplineSpeed = SplineDir.DotProduct(Velocity);
		SplineSpeed += SplineComp.Speed * MoveSettings.GroundFriction * DeltaTime; // Always forward acc along spline
		SplineSpeed *= Math::Pow(Integratedfriction, DeltaTime);
		SplineComp.DistanceAlongSpline += SplineSpeed * DeltaTime;
		FVector NewLoc = Spline.GetLocationAtDistance(SplineComp.DistanceAlongSpline);
		Movement.AddDeltaFromMoveToPositionWithCustomVelocity(NewLoc, SplineDir * SplineSpeed);

		// Turn towards focus?
		if (DestinationComp.Focus.IsValid())
			MoveComp.RotateTowardsDirection(DestinationComp.Focus.GetFocusLocation() - Owner.FocusLocation, MoveSettings.TurnDuration, DeltaTime, Movement, true);
		// Turn in direction of spline when we have a destination
		else if (DestinationComp.HasDestination() && !SplineDir.IsZero())
			MoveComp.RotateTowardsDirection(SplineDir, MoveSettings.TurnDuration, DeltaTime, Movement, true);
		// Slow to a stop if we've nothing better to do
		else  
			MoveComp.StopRotating(MoveSettings.StopTurningDamping, DeltaTime, Movement);

#if EDITOR
		//Owner.bHazeEditorOnlyDebugBool = true;
		if (Owner.bHazeEditorOnlyDebugBool)
		{
			TArray<FVector> DbgLocs;
			SplineComp.Spline.GetLocations(DbgLocs, 100);
			for (int i = 1; i < DbgLocs.Num(); i++)
			{
				Debug::DrawDebugLine(DbgLocs[i-1], DbgLocs[i], FLinearColor::Purple, 5);
			}
			SplineComp.Spline.DrawDebugSpline();
		}
#endif	
	}
}
