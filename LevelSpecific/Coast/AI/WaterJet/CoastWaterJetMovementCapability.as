class UCoastWaterJetMovementCapability : UHazeCapability
{
	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;

	default CapabilityTags.Add(CapabilityTags::Movement);
	
	default TickGroup = EHazeTickGroup::ActionMovement;
	default TickGroupOrder = 50;
	default DebugCategory = CapabilityTags::Movement;

	UCoastWaterJetSettings Settings;
	UCoastWaterJetComponent WaterJetComp;
	UBasicAICharacterMovementComponent MoveComp;
	UBasicAIDestinationComponent DestinationComp;
	UHazeCrumbSyncedActorPositionComponent CrumbMotionComp;

	USimpleMovementData Movement;

	FVector BaseVelocity;
    FVector CustomVelocity;
	FVector PrevLocation;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Settings = UCoastWaterJetSettings::GetSettings(Owner);
		WaterJetComp = UCoastWaterJetComponent::GetOrCreate(Owner);
		DestinationComp = UBasicAIDestinationComponent::GetOrCreate(Owner);
		CrumbMotionComp = UHazeCrumbSyncedActorPositionComponent::GetOrCreate(Owner); // This has to be created before MoveComp runs BeginPlay
		MoveComp = UBasicAICharacterMovementComponent::GetOrCreate(Owner);
		Movement = MoveComp.SetupSimpleMovementData();
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (DestinationComp.bHasPerformedMovement)
			return false;
		if (WaterJetComp.Train == nullptr)
			return false;
		if (OceanWaves::GetOceanWavePaint() == nullptr)
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
		WaterJetComp.RailPosition = WaterJetComp.Train.RailSpline.GetClosestSplinePositionToWorldLocation(Owner.ActorLocation);
		if (Owner.AttachParentActor != nullptr)
			Owner.DetachRootComponentFromParent();
		MoveComp.AddMovementIgnoresActor(this, OceanWaves::GetOceanWavePaint().TargetLandscape);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		MoveComp.RemoveMovementIgnoresActor(this);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{	
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

		MoveComp.ApplyMove(Movement);
		DestinationComp.bHasPerformedMovement = true;
	}

	void ComposeMovement(float DeltaTime)
	{	
		FVector OwnLoc = Owner.ActorLocation;
		FVector Destination = DestinationComp.Destination;

		if (DestinationComp.Speed < 1.0)
		{
			// No destination, let friction slow us to a stop 
			DestinationComp.ReportStopping();
		}
		else if (OwnLoc.IsWithinDist(Destination, Settings.AtDestinationRange))
		{
			// Close to destination, just drift
		}
		else
		{
			// Accelerate towards destination, constrained along wave slope
			FVector AccDir = (Destination - OwnLoc);
			AccDir = AccDir.GetSafeNormal();
			BaseVelocity += AccDir * DestinationComp.Speed * DeltaTime;				
		}

		// Apply friction 
		float IntegratedFriction = Math::Exp(-Settings.AirFriction);
		BaseVelocity *= Math::Pow(IntegratedFriction, DeltaTime);

		// Apply finished velocity
		Movement.AddVelocity(BaseVelocity);

		// Custom acceleration
		CustomVelocity += DestinationComp.CustomAcceleration * DeltaTime;
		CustomVelocity *= Math::Pow(IntegratedFriction, DeltaTime);
		Movement.AddVelocity(CustomVelocity);

		// Keep station with train
		FVector RailOffset = WaterJetComp.RailPosition.WorldTransform.InverseTransformPosition(OwnLoc);
		float FollowSpeed = WaterJetComp.Train.ActorVelocity.DotProduct(WaterJetComp.RailPosition.WorldForwardVector);
		WaterJetComp.RailPosition.Move(FollowSpeed * DeltaTime);
		FVector StationKeepingLoc = WaterJetComp.RailPosition.WorldTransform.TransformPosition(RailOffset); 
		Movement.AddDelta(StationKeepingLoc - OwnLoc);

		// Adjust rail position to match actual position
		WaterJetComp.RailPosition.Move(Math::Clamp(RailOffset.X, -10000.0, 10000.0) * DeltaTime);

		// Turn towards focus or direction of move
		FRotator Rotation;
		if (DestinationComp.Focus.IsValid())
			Rotation = MoveComp.GetRotationTowardsDirection(DestinationComp.Focus.GetFocusLocation() - Owner.FocusLocation, Settings.TurnDuration, DeltaTime);
		else if (DestinationComp.HasDestination() && !OwnLoc.IsWithinDist(Destination, Settings.AtDestinationRange))
			Rotation = MoveComp.GetRotationTowardsDirection((Destination - OwnLoc).GetSafeNormal(), Settings.TurnDuration, DeltaTime);
		else  
			Rotation = MoveComp.GetStoppedRotation(Settings.StopTurningDamping, DeltaTime);
		Movement.SetRotation(Rotation);

#if EDITOR
		//Owner.bHazeEditorOnlyDebugBool = true;
		if (Owner.bHazeEditorOnlyDebugBool)
		{
			Debug::DrawDebugLine(Destination, OwnLoc, FLinearColor::LucBlue);		
		 	//Debug::DrawDebugSolidPlane(WaterJetComp.WaveData.PointOnWave, WaterJetComp.WaveData.PointOnWaveNormal, 400, 400, FLinearColor::Blue);
			Debug::DrawDebugLine(WaterJetComp.RailPosition.WorldLocation, WaterJetComp.RailPosition.WorldLocation + FVector(0,0,1000), FLinearColor::Green, 20); 	
		}
#endif
	}
}
