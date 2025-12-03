class UTundraFishieSwimmingMovementCapability : UHazeCapability
{	
	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;

	default CapabilityTags.Add(CapabilityTags::Movement);
	default CapabilityTags.Add(n"SwimmingMovement");	

	default DebugCategory = CapabilityTags::Movement;

	default TickGroup = EHazeTickGroup::ActionMovement;

	UBasicAICharacterMovementComponent MoveComp;
	UBasicAIDestinationComponent DestinationComp;
	UHazeCrumbSyncedActorPositionComponent CrumbMotionComp;
	UBasicAIAnimationComponent AnimComp;
	UBasicAIMovementSettings MoveSettings;
	USimpleMovementData Movement;
	FVector PrevLocation;
	FHazeAcceleratedRotator AccRot;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		DestinationComp = UBasicAIDestinationComponent::GetOrCreate(Owner);
		CrumbMotionComp = UHazeCrumbSyncedActorPositionComponent::GetOrCreate(Owner); // This has to be created before MoveComp runs BeginPlay
		MoveComp = UBasicAICharacterMovementComponent::GetOrCreate(Owner);
		AnimComp = UBasicAIAnimationComponent::GetOrCreate(Owner);
		MoveSettings = UBasicAIMovementSettings::GetSettings(Owner);
		Movement = MoveComp.SetupSimpleMovementData();
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
		AccRot.SnapTo(Owner.ActorRotation);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{	
		AccRot.AccelerateTo(GetIdealRotation(), 3.0, DeltaTime);
		if(!MoveComp.PrepareMove(Movement, AccRot.Value.UpVector))
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
		}

		MoveComp.ApplyMoveAndRequestLocomotion(Movement, AnimComp.FeatureTag);
		DestinationComp.bHasPerformedMovement = true;
	}

	FRotator GetIdealRotation()
	{
		if (HasControl())
		{
			if (DestinationComp.HasDestination() && !Owner.ActorLocation.IsWithinDist(DestinationComp.Destination, 10.0))
				return FRotator::MakeFromXZ(DestinationComp.Destination - Owner.ActorLocation, FVector::UpVector);
			return FRotator::MakeFromZX(FVector::UpVector, Owner.ActorForwardVector);	
		}
		else
		{
			FHazeSyncedActorPosition CrumbPos = MoveComp.GetCrumbSyncedPosition();
			return CrumbPos.WorldRotation;		
		}
	}

	void ComposeMovement(float DeltaTime)
	{
		FVector OwnLoc = Owner.ActorLocation;
		FVector Velocity = MoveComp.Velocity;
		float Friction = MoveSettings.AirFriction;

		FVector Destination = DestinationComp.Destination;

		FVector ToDest = (Destination - OwnLoc);
		float DestDist = ToDest.Size();
		FVector DestDir = (DestDist > 1.0) ? ToDest / DestDist : Owner.ActorForwardVector;
		if (DestinationComp.HasDestination() && (DestDist > 1.0))
		{
			float Acceleration = DestinationComp.Speed;

			// Accelerate right/left to turn towards destination if we're off
			FVector CurDir = Velocity.IsNearlyZero(10.0) ? Owner.ActorForwardVector : Velocity.GetSafeNormal();
			float DestAccFactor = 1.0;
			if (CurDir.DotProduct(DestDir) < 1.0 - SMALL_NUMBER)
			{
				FVector TurnPlaneNormal = CurDir.CrossProduct(DestDir);
				FVector TurnCross = TurnPlaneNormal.CrossProduct(CurDir);
				Velocity += TurnCross * Acceleration * DeltaTime;
				DestAccFactor = 1.0 - TurnCross.Size();
			}

			// Accelerate directly towards destination with remaining acceleration fraction
			Velocity += DestDir * Acceleration * DestAccFactor * DeltaTime;
		}
		else
		{
			// No destination, let friction slow us to a stop 
			DestinationComp.ReportStopping();
		}

		// Apply friction
		Velocity -= Velocity * Friction * DeltaTime;
	
		Movement.AddVelocity(Velocity);

		// Turn towards focus or direction of move
		if (DestinationComp.Focus.IsValid())
			MoveComp.RotateTowardsDirection(DestinationComp.Focus.GetFocusLocation() - Owner.FocusLocation, MoveSettings.TurnDuration, DeltaTime, Movement);
		else if (DestinationComp.HasDestination() && !OwnLoc.IsWithinDist(Destination, 40.0))
			MoveComp.RotateTowardsDirection(DestDir, MoveSettings.TurnDuration, DeltaTime, Movement);
		else  
			MoveComp.StopRotating(MoveSettings.StopTurningDamping, DeltaTime, Movement);

		Movement.AddPendingImpulses();
	}
}
