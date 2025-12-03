class USummitStoneBeastCritterMovementCapability : UHazeCapability
{	
	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;
	
	default CapabilityTags.Add(CapabilityTags::Movement);
	default CapabilityTags.Add(n"GroundMovement");	

	default TickGroup = EHazeTickGroup::ActionMovement;
	default TickGroupOrder = 100;

	default DebugCategory = CapabilityTags::Movement;



	UBasicAICharacterMovementComponent MoveComp;
	UBasicAIDestinationComponent DestinationComp;
	UPathfollowingMoveToComponent PathFollowingComp;
	UHazeCrumbSyncedActorPositionComponent CrumbMotionComp;
	UBasicAIAnimationComponent AnimComp;
	UHazeActorRespawnableComponent RespawnComp;
	USceneComponent ParentActorComponent;

	UPathfollowingSettings PathingSettings;
	UGroundPathfollowingSettings GroundPathfollowingSettings;
	UBasicAIMovementSettings MoveSettings;	
	UTeleportingMovementData Movement;

    FVector CustomVelocity;
	FVector PrevLocation;

	FHitResult PreviousGroundHit;
	float PreviousGroundHeight = 0.0;
	bool bHasGroundHeight = false;
	uint GroundUpdatePhase = 0;
	
	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		DestinationComp = UBasicAIDestinationComponent::GetOrCreate(Owner);
		PathFollowingComp = UPathfollowingMoveToComponent::GetOrCreate(Owner);
		CrumbMotionComp = UHazeCrumbSyncedActorPositionComponent::GetOrCreate(Owner); // This has to be created before MoveComp runs BeginPlay
		CrumbMotionComp.OverrideSyncRate(EHazeCrumbSyncRate::Low);
		MoveComp = UBasicAICharacterMovementComponent::GetOrCreate(Owner);
		AnimComp = UBasicAIAnimationComponent::GetOrCreate(Owner);
		PathingSettings = UPathfollowingSettings::GetSettings(Owner);
		MoveSettings = UBasicAIMovementSettings::GetSettings(Owner);
		GroundPathfollowingSettings = UGroundPathfollowingSettings::GetSettings(Owner);
		RespawnComp = UHazeActorRespawnableComponent::GetOrCreate(Owner);
		RespawnComp.OnRespawn.AddUFunction(this, n"OnRespawn");
		Movement = MoveComp.SetupTeleportingMovementData();
	}
	

	UFUNCTION()
	private void OnRespawn()
	{
		MoveComp.UnFollowComponentMovement(this);
		MoveComp.ClearFollowEnabledOverride(this);
		
		TryFollowComponentMovement();
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
		if (Owner.AttachParentActor != nullptr)
			return true;

		if (DestinationComp.bHasPerformedMovement)
			return true;
		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		MoveComp.AccRotation.SnapTo(Owner.ActorRotation);
		PrevLocation = Owner.ActorLocation;
		GroundUpdatePhase = Owner.Name.Hash % 3;
		
		TryFollowComponentMovement();
	}
	
	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		MoveComp.UnFollowComponentMovement(this);
		MoveComp.ClearFollowEnabledOverride(this);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if (Owner.AttachParentActor  != nullptr)
		{
			TryFollowComponentMovement();
			return;
		}

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
			ApplyCrumbSyncedMovement(Velocity);
			PrevLocation = Owner.ActorLocation;
		}

		MoveComp.ApplyMoveAndRequestLocomotion(Movement, AnimComp.FeatureTag);
		DestinationComp.bHasPerformedMovement = true;
	}

	void ApplyCrumbSyncedMovement(FVector Velocity)
	{
		Movement.ApplyCrumbSyncedGroundMovementWithCustomVelocity(Velocity);			
	}

void ComposeMovement(float DeltaTime)
	{	
#if !RELEASE
		FTemporalLog TemporalLog = TEMPORAL_LOG(this);
#endif

		FVector OwnLoc = Owner.ActorLocation;
		FVector Velocity = MoveComp.Velocity;
		Velocity -= CustomVelocity; 

		FVector Destination = GetCurrentDestination();
		FVector HorizontalVelocity = Velocity.ConstrainToPlane(MoveComp.WorldUp);
		FVector VerticalVelocity = Velocity - HorizontalVelocity;
		FVector MoveDir = (Destination - OwnLoc).ConstrainToPlane(MoveComp.WorldUp).GetSafeNormal();

#if !RELEASE
		TemporalLog.Sphere("Initial;OwnLoc", OwnLoc, 50, FLinearColor::LucBlue);
		TemporalLog.DirectionalArrow("Initial;Velocity", OwnLoc, Velocity);
		TemporalLog.Sphere("Initial;Destination", Destination, 50, FLinearColor::Green);
		TemporalLog.DirectionalArrow("Initial;HorizontalVelocity", OwnLoc, HorizontalVelocity);
		TemporalLog.DirectionalArrow("Initial;VerticalVelocity", OwnLoc, VerticalVelocity);
		TemporalLog.DirectionalArrow("Initial;MoveDir", OwnLoc, MoveDir);
		TemporalLog.Value("Initial;HasDestination", DestinationComp.HasDestination());
#endif
		
		if (DestinationComp.HasDestination()) 
		{
			float MoveSpeed = DestinationComp.Speed;
			FHazeAcceleratedVector AccLocation;
			AccLocation.SnapTo(OwnLoc, HorizontalVelocity);

#if !RELEASE
			TemporalLog.Value("HasDestination;MoveSpeed", MoveSpeed);
#endif

			if (IsMovingToFinalDestination() && OwnLoc.IsWithinDist(Destination, PathingSettings.AtDestinationRange))
			{
				// Slow to a stop
				AccLocation.AccelerateTo(Destination, 1.0, DeltaTime);
				
				// Keep applying slowed down velocity until we're moving away from destination 
				// TODO: this can be handled better, but will at least stop overshoot sliding on slopes.
				if (MoveDir.DotProduct(HorizontalVelocity) > 0.0) 
					Movement.AddVelocity(HorizontalVelocity);

				// MoveTo is completed (note that this will usually mean this capability will deactivate)
				PathFollowingComp.ReportComplete(true);

#if !RELEASE
				TemporalLog.Status("Slow to a Stop", FLinearColor::Red);
				TemporalLog.Sphere("HasDestination;AccLocation Value", AccLocation.Value, 50);
				TemporalLog.DirectionalArrow("HasDestination;AccLocation Velocity", AccLocation.Value, AccLocation.Velocity);
#endif
			}
			else
			{
				// Less yanky version of Move towards destination:
				// FVector TargetLocation = OwnLoc + MoveDir * MoveSpeed;
				// FPlane DestinationPlane = FPlane(Destination, MoveDir);
				// if(TargetLocation.IsAbovePlane(DestinationPlane))
				// 	TargetLocation = TargetLocation.PointPlaneProject(Destination, MoveDir);

				// AccLocation.AccelerateTo(TargetLocation, GroundPathfollowingSettings.AccelerationDuration, DeltaTime); 
				//const FVector ClampedVelocity = AccLocation.Velocity.GetClampedToMaxSize(MoveSpeed); // Hacky clamp but this will be replaced
				// Movement.AddVelocity(ClampedVelocity);


				// Move towards destination
				AccLocation.AccelerateTo(OwnLoc + MoveDir * MoveSpeed, GroundPathfollowingSettings.AccelerationDuration, DeltaTime);
				const FVector ClampedVelocity = AccLocation.Velocity.GetClampedToMaxSize(MoveSpeed); // Hacky clamp but this will be replaced
				Movement.AddVelocity(ClampedVelocity);
				
#if !RELEASE
				TemporalLog.Status("Move towards destination", FLinearColor::Green);
				TemporalLog.Sphere("HasDestination;AccLocation Value", AccLocation.Value, 50);
				TemporalLog.DirectionalArrow("HasDestination;AccLocation Velocity", AccLocation.Value, AccLocation.Velocity);
				TemporalLog.DirectionalArrow("HasDestination;ClampedVelocity", OwnLoc, ClampedVelocity);
#endif
			}
		}
		else
		{
			// No destination, slow to a stop
			DestinationComp.ReportStopping();
			float Friction = MoveComp.IsInAir() ? MoveSettings.AirFriction : MoveSettings.GroundFriction;
			HorizontalVelocity -= HorizontalVelocity * Friction * DeltaTime;
			Movement.AddVelocity(HorizontalVelocity);
			VerticalVelocity -= VerticalVelocity * Friction * DeltaTime;

#if !RELEASE
			TemporalLog.Status("No destination, slow to a stop", FLinearColor::Yellow);
#endif
		}

		CustomVelocity += DestinationComp.CustomAcceleration * DeltaTime;
		float Friction = MoveComp.IsOnWalkableGround() ? MoveSettings.GroundFriction : MoveSettings.AirFriction;
		CustomVelocity -= CustomVelocity * Friction * DeltaTime;
		Movement.AddVelocity(CustomVelocity);

#if !RELEASE
		TemporalLog.DirectionalArrow("Final;CustomVelocity", OwnLoc, CustomVelocity);
#endif

		// Turn towards focus?
		if (DestinationComp.Focus.IsValid())
			MoveComp.RotateTowardsDirection(DestinationComp.Focus.GetFocusLocation() - Owner.FocusLocation, MoveSettings.TurnDuration, DeltaTime, Movement);
		// Turn towards destination if still some ways off
		else if (DestinationComp.HasDestination() && !OwnLoc.IsWithinDist(Destination, PathingSettings.AtDestinationRange))
			MoveComp.RotateTowardsDirection(MoveDir, MoveSettings.TurnDuration, DeltaTime, Movement);
		// Slow to a stop
		else  
			MoveComp.StopRotating(MoveSettings.StopTurningDamping, DeltaTime, Movement);

		// Find the ground height every few frames. We spread out these traces over time for performance
		if (!bHasGroundHeight || GFrameNumber % 3 == GroundUpdatePhase)
		{
			FHazeTraceSettings GroundTrace;
			GroundTrace.UseLine();
			GroundTrace.TraceWithProfile(n"EnemyIgnoreCharacters");

			FHitResult GroundHit = GroundTrace.QueryTraceSingle(
				Owner.ActorLocation + FVector(0, 0, 200),
				Owner.ActorLocation - FVector(0, 0, 600)
			);
			GroundTrace.DebugDrawOneFrame();

			if (GroundHit.bBlockingHit && !GroundHit.bStartPenetrating)
			{
				PreviousGroundHeight = GroundHit.ImpactPoint.Z;
				PreviousGroundHit = GroundHit;
				bHasGroundHeight = true;
			}
			else
			{
				PreviousGroundHit = FHitResult();
				if (!GroundHit.bStartPenetrating)
					PreviousGroundHeight = Owner.ActorLocation.Z - 600;
			}
		}

		// Move down to the ground
		if (bHasGroundHeight) 
		{
			// Debug::DrawDebugSphere(FVector(Owner.ActorLocation.X, Owner.ActorLocation.Y, PreviousGroundHeight), 10);
			if (VerticalVelocity.Z > 0)
			{
				Movement.AddVelocity(VerticalVelocity);
				Movement.AddGravityAcceleration();
			}
			else
			{
				float CurrentHeight = Owner.ActorLocation.Z;
				if (CurrentHeight > PreviousGroundHeight)
				{
					float DownVelocity = VerticalVelocity.Z;
					DownVelocity += -MoveComp.GravityForce * DeltaTime;

					float DownDelta = Math::Max(DownVelocity * DeltaTime, PreviousGroundHeight - CurrentHeight);
					if (Math::Abs(DownDelta) > 0.001)
						Movement.AddDelta(FVector(0, 0, DownDelta));
				}
				else if (CurrentHeight > PreviousGroundHeight - 100)
				{
					Movement.AddDeltaWithCustomVelocity(FVector(0, 0, PreviousGroundHeight - CurrentHeight), FVector::ZeroVector);
				}

				Movement.OverrideFinalGroundResult(PreviousGroundHit);
			}
		}

		Movement.AddPendingImpulses();
	}

	FVector GetCurrentDestination()
	{
		if (PathingSettings.bIgnorePathfinding)
			return DestinationComp.Destination;

		return PathFollowingComp.GetPathfindingDestination();	
	}

	bool IsMovingToFinalDestination()
	{
		if (PathingSettings.bIgnorePathfinding)
			return true;

		return PathFollowingComp.IsMovingToFinalDestination();
	}
	
	// See if attached to something and try to switch to FollowComponentMovement
	void TryFollowComponentMovement()
	{
		// Check if already attached from MoveAlongSplineCapability.
		USceneComponent AttachmentComp = MoveComp.GetCurrentMovementAttachmentComponent();
		if (AttachmentComp != nullptr)
			return;

		ParentActorComponent = Owner.RootComponent.AttachParent;
		
		if (ParentActorComponent == nullptr && RespawnComp.Spawner != nullptr)
			ParentActorComponent = RespawnComp.Spawner.RootComponent.AttachParent;

		if (ParentActorComponent != nullptr)
		{
			Owner.DetachRootComponentFromParent();
			MoveComp.ApplyFollowEnabledOverride(this, EMovementFollowEnabledStatus::FollowEnabled);			
			MoveComp.FollowComponentMovement(ParentActorComponent, this, EMovementFollowComponentType::Teleport, EInstigatePriority::Normal);			
		}
	}
}
