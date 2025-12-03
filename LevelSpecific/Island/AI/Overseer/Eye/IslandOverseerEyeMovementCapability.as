class UIslandOverseerEyeMovementCapability : UBasicAIMovementCapability
{	
	default CapabilityTags.Add(n"FlyingMovement");	

	UHazeCrumbSyncedRotatorComponent SyncedRotator;
	USimpleMovementData SlidingMovement;
	AHazeActor Boss;
	AAIIslandOverseerEye Eye;
	FHazeAcceleratedRotator AccRot;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Super::Setup();
		SyncedRotator = UHazeCrumbSyncedRotatorComponent::Get(Owner);
		SlidingMovement = Cast<USimpleMovementData>(Movement);
		Eye = Cast<AAIIslandOverseerEye>(Owner);
		Boss = Cast<AAIIslandOverseerEye>(Owner).Boss;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		Super::OnActivated();
		AccRot.SnapTo(Eye.MeshOffsetComponent.WorldRotation);
	}

	UBaseMovementData SetupMovementData() override
	{
		return MoveComp.SetupSimpleMovementData();
	} 

	bool PrepareMove() override
	{
		return MoveComp.PrepareMove(SlidingMovement);
	}

	void ComposeMovement(float DeltaTime) override
	{
		FVector OwnLoc = Owner.ActorLocation;
		FVector Velocity = MoveComp.Velocity;
		Velocity -= CustomVelocity;
		float Friction = MoveSettings.AirFriction;

		FVector Destination = DestinationComp.Destination;

		FVector ToDest = (Destination - OwnLoc);
		float DestDist = ToDest.Size();
		FVector DestDir = (DestDist > 1.0) ? ToDest / DestDist : Eye.MeshOffsetComponent.ForwardVector;
		if (DestinationComp.HasDestination() && (DestDist > 1.0))
		{
			float Acceleration = DestinationComp.Speed;

			// Accelerate right/left to turn towards destination if we're off
			FVector CurDir = Velocity.IsNearlyZero(10.0) ? Eye.MeshOffsetComponent.ForwardVector : Velocity.GetSafeNormal();
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
		Velocity = Velocity.ConstrainToPlane(Boss.ActorForwardVector);
		Movement.AddVelocity(Velocity);

		if(DestinationComp.Focus.IsValid())
			AccRot.AccelerateTo((DestinationComp.Focus.GetFocusLocation() - Owner.FocusLocation).Rotation(), MoveSettings.TurnDuration, DeltaTime);
		else
			AccRot.AccelerateTo(Velocity.Rotation(), MoveSettings.TurnDuration, DeltaTime);
		Eye.MeshOffsetComponent.SetWorldRotation(FRotator::MakeFromXY(AccRot.Value.ForwardVector, Eye.Boss.ActorForwardVector));
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		Super::TickActive(DeltaTime);
		if(HasControl())
			SyncedRotator.Value = Eye.MeshOffsetComponent.WorldRotation;
		else
			Eye.MeshOffsetComponent.WorldRotation = SyncedRotator.Value;
	}
}
