class USkylineGeckoPathfindingMovementCapability : UHazeCapability
{	
	default CapabilityTags.Add(CapabilityTags::Movement);
	default CapabilityTags.Add(n"WallclimbingMovement");	

	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;

	default TickGroup = EHazeTickGroup::ActionMovement;
	default DebugCategory = CapabilityTags::Movement;

	UBasicAICharacterMovementComponent MoveComp;
	UBasicAIDestinationComponent DestinationComp;
	UHazeCrumbSyncedActorPositionComponent CrumbMotionComp;
	UPathfollowingMoveToComponent PathFollowingComp;
	UHazeCapsuleCollisionComponent CollisionComp;

	UWallclimbingComponent WallclimbingComp;
	UBasicAIRuntimeSplineComponent SplineComp;
	USkylineGeckoFloorProbeComponent ProbeComp;
	UWallclimbingPathfollowingSettings WallPathfollowingSettings;
	UPathfollowingSettings PathingSettings;
	USkylineGeckoSettings Settings;

	USteppingMovementData Movement;

	FVector PrevLocation;

	FHazeAcceleratedRotator AccNonPathUp;
	float DefaultRadius = 100.0;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		DestinationComp = UBasicAIDestinationComponent::GetOrCreate(Owner);
		CrumbMotionComp = UHazeCrumbSyncedActorPositionComponent::GetOrCreate(Owner); // This has to be created before MoveComp runs BeginPlay
		PathFollowingComp = UPathfollowingMoveToComponent::GetOrCreate(Owner) ;
		MoveComp = UBasicAICharacterMovementComponent::GetOrCreate(Owner);
		Movement = MoveComp.SetupSteppingMovementData();
		WallclimbingComp = UWallclimbingComponent::GetOrCreate(Owner);
		SplineComp = UBasicAIRuntimeSplineComponent::GetOrCreate(Owner); 
		ProbeComp = USkylineGeckoFloorProbeComponent::GetOrCreate(Owner);
		CollisionComp = Cast<AHazeCharacter>(Owner).CapsuleComponent;
		WallPathfollowingSettings = UWallclimbingPathfollowingSettings::GetSettings(Owner);
		PathingSettings = UPathfollowingSettings::GetSettings(Owner);
		Settings = USkylineGeckoSettings::GetSettings(Owner);

		PathFollowingComp.OnFoundNewPath.AddUFunction(this, n"OnFoundNewPath");
		DefaultRadius = CollisionComp.CapsuleRadius;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (DestinationComp.bHasPerformedMovement)
			return false;
	    return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (DestinationComp.bHasPerformedMovement)
			return true;
        return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		MoveComp.AccRotation.SnapTo(Owner.ActorRotation);
		PrevLocation = Owner.ActorLocation;
		AccNonPathUp.SnapTo(Owner.ActorUpVector.Rotation());
		if (!SplineComp.HasSpline())
			UpdatePathSpline();
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		SplineComp.Reset();
		CollisionComp.CapsuleRadius = DefaultRadius;
		CollisionComp.CapsuleHalfHeight = DefaultRadius;
	}

	UFUNCTION()
	private void OnFoundNewPath()
	{
		if (!IsActive())
			return;
		UpdatePathSpline();
	}

	void UpdatePathSpline()
	{
		FVector OwnLoc = Owner.ActorLocation;
		TArray<FVector> SplineLocs;
		TArray<FVector> SplineUpVecs;
		if (WallclimbingComp.Path.Num() > 0)
		{
			SplineLocs.Add(OwnLoc);
			SplineUpVecs.Add(Owner.ActorUpVector);

			// Skip initial nodes that we have passed
			const float SkipDistance = 60.0;
			int iFirst = 1; // Always skip first node
			for (int i = WallclimbingComp.Path.Num() - 1; i >= iFirst; i--) 
			{
				FVector CurLoc = WallclimbingComp.Path[i].Location;
				FVector PrevLoc = WallclimbingComp.Path[i-1].Location;
				FVector ClosestLoc;
				float Dummy;
				Math::ProjectPositionOnLineSegment(PrevLoc, CurLoc, OwnLoc, ClosestLoc, Dummy);
				if (OwnLoc.IsWithinDist(ClosestLoc, SkipDistance))
					iFirst = i;
			}

			// Add spline points for remaining nodes
			const float IntermediateDistance = 100.0;
			FVector PrevLoc = OwnLoc;
			for (int i = iFirst; i < WallclimbingComp.Path.Num(); i++) // Always skip first node
			{
				const FWallClimbingPathNode& Node = WallclimbingComp.Path[i];
				if (!PrevLoc.IsWithinDist(Node.Location, IntermediateDistance))
				{
					// Path stretch leading up to current node is rather long, add intermediate node
					FVector StretchDir = (Node.Location - PrevLoc).GetSafeNormal();
					SplineLocs.Add(PrevLoc + StretchDir * IntermediateDistance);
					SplineUpVecs.Add(SplineUpVecs.Last());

					// Add a second point before this if it fits
					if (!SplineLocs.Last().IsWithinDist(Node.Location, IntermediateDistance))
					{
						SplineLocs.Add(Node.Location - StretchDir * IntermediateDistance);
						SplineUpVecs.Add(SplineUpVecs.Last());
					}
				}
				// Add location for current node
				SplineLocs.Add(Node.Location);
				SplineUpVecs.Add(Node.Normal);
				PrevLoc = Node.Location;
			}
		}
		if (SplineLocs.Num() < 2)
		{
			// No path!
			SplineComp.Reset();
			return;
		}

		// Wallclimbing navmesh does not fit ground very well
		// TODO: We can post process path with one trace per frame instead to spread out cost
		// or ideally snap the wallclimbing navmesh onto the existing geometry
		FHazeTraceSettings Trace = Trace::InitFromMovementComponent(MoveComp);
		for (int i = 1; i < SplineLocs.Num(); i++)
		{
			FVector Start = SplineLocs[i] + SplineUpVecs[i] * 10.0;
			FVector End = SplineLocs[i] - SplineUpVecs[i] * 80.0;
			FHitResult Obstruction = Trace.QueryTraceSingle(Start, End);	
			if (Obstruction.bBlockingHit)
				SplineLocs[i] = Obstruction.ImpactPoint;
			else
				SplineLocs[i] = End;
		}

		// We have a new path
		FHazeRuntimeSpline Spline;
		Spline.SetTension(0.5); // Fairly harsh spline
		Spline.SetCustomEnterTangentPoint(OwnLoc - Owner.ActorForwardVector);
		Spline.SetPointsAndUpDirections(SplineLocs, SplineUpVecs);
		SplineComp.SetSpline(Spline);
		SplineComp.DistanceAlongSpline = 0.0;
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if(!MoveComp.PrepareMove(Movement, GetUpDirection(DeltaTime)))
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
			PrevLocation = Owner.ActorLocation;
		}

		MoveComp.ApplyMove(Movement);
		DestinationComp.bHasPerformedMovement = true;
	}

	FVector GetUpDirection(float DeltaTime)
	{
		if (HasControl())
		{
			if (!SplineComp.HasSpline() || !DestinationComp.HasDestination())
			{
				FVector FloorUp = ProbeComp.GetFloorUp();
				if (FloorUp == FVector::ZeroVector)
					FloorUp = MoveComp.WorldUp;
				AccNonPathUp.AccelerateTo(FloorUp.Rotation(), 2.0, DeltaTime);				
				return AccNonPathUp.Value.Vector();
			}

			return SplineComp.Spline.GetUpDirectionAtDistance(SplineComp.DistanceAlongSpline);
		}

		// Remote, use replicated rotation
		FHazeSyncedActorPosition CrumbPos = MoveComp.GetCrumbSyncedPosition();
		return CrumbPos.WorldRotation.UpVector;		
	}

	void ComposeMovement(float DeltaTime)
	{	
		// Test skipping pathfollowing stuff and use own dynamic spline instead
		FVector OwnLoc = Owner.ActorLocation;
		FVector Velocity = MoveComp.Velocity;
		float Integratedfriction = Math::Exp(-Settings.GroundFriction);
		FVector SplineDir = FVector::ZeroVector;

		if (!DestinationComp.HasDestination() || 
			!SplineComp.HasSpline() || 
			SplineComp.IsNearEndOfSpline(40.0))
		{
			// No destination or at destination, slow to a stop
			SplineComp.DistanceAlongSpline = SplineComp.HasSpline() ? SplineComp.Spline.Length : 0.0;
			Velocity *= Math::Pow(Integratedfriction, DeltaTime);
			Movement.AddVelocity(Velocity);
			DestinationComp.ReportStopping();

			Movement.AddGravityAcceleration();

			// Restore collision size			
			CollisionComp.CapsuleRadius = DefaultRadius;
			CollisionComp.CapsuleHalfHeight = DefaultRadius;
		}
		else
		{
			// Move along spline 
			SplineDir = SplineComp.Spline.GetDirectionAtDistance(SplineComp.DistanceAlongSpline).GetSafeNormal();
			float SplineSpeed = SplineDir.DotProduct(Velocity);
			SplineSpeed += DestinationComp.Speed * Settings.GroundFriction * DeltaTime; // Always forward acc along spline
			SplineSpeed *= Math::Pow(Integratedfriction, DeltaTime);
			SplineComp.DistanceAlongSpline += SplineSpeed * DeltaTime;
			FVector NewLoc = SplineComp.Spline.GetLocationAtDistance(SplineComp.DistanceAlongSpline);
			Movement.AddDeltaFromMoveToPositionWithCustomVelocity(NewLoc, SplineDir * SplineSpeed);

			// Reduce collision size to get past tricky obstacles
			CollisionComp.CapsuleRadius = DefaultRadius * 0.4;
			CollisionComp.CapsuleHalfHeight = DefaultRadius * 0.4;
		}

		// Turn towards focus?
		if (DestinationComp.Focus.IsValid())
			MoveComp.RotateTowardsDirection(DestinationComp.Focus.GetFocusLocation() - Owner.FocusLocation, Settings.TurnDuration, DeltaTime, Movement, true);
		// Turn in direction of spline when we have a destination
		else if (DestinationComp.HasDestination() && !SplineDir.IsZero())
			MoveComp.RotateTowardsDirection(SplineDir, Settings.TurnDuration, DeltaTime, Movement, true);
		// Always rotate when we're not aligned with gravity
		else if (MoveComp.WorldUp.DotProduct(Owner.ActorUpVector) < 0.99)
			MoveComp.RotateTowardsDirection(Owner.ActorForwardVector, Settings.TurnDuration, DeltaTime, Movement);
		// Slow to a stop if we've nothing better to do
		else  
			MoveComp.StopRotating(5.0, DeltaTime, Movement);
		// TODO: Custom acceleration and Movement.AddPendingImpulses();

#if EDITOR
		//Owner.bHazeEditorOnlyDebugBool = true;
		if (Owner.bHazeEditorOnlyDebugBool)
		{
			int nPoints = 100;
			TArray<FVector> SplineLocs;
			SplineComp.Spline.GetLocations(SplineLocs, nPoints);
			TArray<FRotator> SplineRots;
			SplineComp.Spline.GetRotations(SplineRots, nPoints);
			for (int i = 1; i < SplineLocs.Num(); i++)
			{
				Debug::DrawDebugLine(SplineLocs[i-1], SplineLocs[i], FLinearColor::Purple);
				if ((i % 2) == 1)
					Debug::DrawDebugLine(SplineLocs[i-1], SplineLocs[i-1] + SplineRots[i - 1].UpVector * 30.0, FLinearColor::DPink);
			}

			for (int i = 1; i < SplineComp.Spline.Points.Num(); i++)
			{
				Debug::DrawDebugLine(SplineComp.Spline.Points[i-1], SplineComp.Spline.Points[i], FLinearColor::DPink);
			}

			int i = 0;
			for (const FWallClimbingPathNode& Node : WallclimbingComp.Path)
			{
			 	Debug::DrawDebugString(Node.Location, "" + i);
				i++;	
			}

			Debug::DrawDebugLine(OwnLoc, OwnLoc + SplineDir * 400, FLinearColor::Green);
		}
#endif
	}
}

