class UCoastJetskiMovementCapability : UHazeCapability
{
	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;

	default CapabilityTags.Add(CapabilityTags::Movement);
	
	default TickGroup = EHazeTickGroup::ActionMovement;
	default TickGroupOrder = 50;
	default DebugCategory = CapabilityTags::Movement;

	UCoastJetskiSettings Settings;
	UCoastJetskiComponent JetskiComp;
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
		Settings = UCoastJetskiSettings::GetSettings(Owner);
		JetskiComp = UCoastJetskiComponent::GetOrCreate(Owner);
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
		if (JetskiComp.Train == nullptr)
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
		JetskiComp.RailPosition = JetskiComp.Train.RailSpline.GetClosestSplinePositionToWorldLocation(Owner.ActorLocation);
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

		OceanWaves::RequestWaveData(this, OwnLoc);
		JetskiComp.WaveData = OceanWaves::GetLatestWaveData(this);

		float Submersion = JetskiComp.Submersion;
		if (DestinationComp.Speed < 1.0)
		{
			// No destination, let friction slow us to a stop 
			DestinationComp.ReportStopping();
		}
		else if (Submersion < -20.0)
		{
			// Lower acceleration when airborne
			FVector AccDir = (Destination - OwnLoc).GetSafeNormal2D();
			BaseVelocity += AccDir * DestinationComp.Speed * 0.5 * DeltaTime;				
		}		
		else 
		{
			// Accelerate towards destination, constrained along wave slope
			FVector AccDir = (Destination - OwnLoc);
			AccDir = AccDir.ConstrainToSlope(JetskiComp.WaveData.PointOnWaveNormal, FVector::UpVector);
			AccDir = AccDir.GetSafeNormal();
			BaseVelocity += AccDir * DestinationComp.Speed * DeltaTime;				
		}

		// Split velocity into horizontal and vertical parts
		FVector Up = Owner.ActorUpVector;
		FVector VerticalVelocity = BaseVelocity.ProjectOnTo(Up);
		FVector HorizontalVelocity = BaseVelocity - VerticalVelocity;

		// Gravity
		VerticalVelocity -= Up * Settings.Gravity * DeltaTime;

		// Buoyancy 
		if (Submersion > 0.0)
			VerticalVelocity += Up * Math::Min(Math::Square(Submersion) * Settings.BuoyancyFactor, Settings.MaxBuoyancy) * DeltaTime;	

		// Apply friction
		float Friction = (Submersion > -20.0) ? Settings.SurfaceFriction : Settings.AirFriction;
		float IntegratedFriction = Math::Exp(-Friction);
		float IntegratedVerticalFriction = IntegratedFriction; 
		if ((Submersion > -20.0) && (VerticalVelocity.DotProduct(Up) < 0.0))  
			IntegratedVerticalFriction = Math::Exp(-Settings.DiveFriction);
		VerticalVelocity *= Math::Pow(IntegratedVerticalFriction, DeltaTime);
		HorizontalVelocity *= Math::Pow(IntegratedFriction, DeltaTime);

		// Recombine and apply	
		BaseVelocity = VerticalVelocity + HorizontalVelocity;
		Movement.AddVelocity(BaseVelocity);

		// Custom acceleration
		CustomVelocity += DestinationComp.CustomAcceleration * DeltaTime;
		CustomVelocity *= Math::Pow(IntegratedFriction, DeltaTime);
		Movement.AddVelocity(CustomVelocity);

		// Keep station with train
		FVector RailOffset = JetskiComp.RailPosition.WorldTransform.InverseTransformPosition(OwnLoc);
		float FollowSpeed = JetskiComp.Train.ActorVelocity.DotProduct(JetskiComp.RailPosition.WorldForwardVector);
		FollowSpeed += JetskiComp.TrainFollowSpeedAdjustment.Get();
		JetskiComp.RailPosition.Move(FollowSpeed * DeltaTime);
		FVector StationKeepingLoc = JetskiComp.RailPosition.WorldTransform.TransformPosition(RailOffset); 
		Movement.AddDelta(StationKeepingLoc - OwnLoc);

		// Adjust rail position to match actual position
		JetskiComp.RailPosition.Move(Math::Clamp(RailOffset.X, -10000.0, 10000.0) * DeltaTime);

		// Align with velocity
		FRotator Rotation = MoveComp.GetRotationTowardsDirection(MoveComp.Velocity - CustomVelocity, Settings.TurnDuration, DeltaTime);
		Movement.SetRotation(Rotation);

#if EDITOR
		//Owner.bHazeEditorOnlyDebugBool = true;
		if (Owner.bHazeEditorOnlyDebugBool)
		{
			Debug::DrawDebugLine(Destination, OwnLoc, FLinearColor::LucBlue);		
			Debug::DrawDebugSphere(JetskiComp.WaveData.PointOnWave, 10, 4, FLinearColor::Green, 5);
		 	//Debug::DrawDebugSolidPlane(JetskiComp.WaveData.PointOnWave, JetskiComp.WaveData.PointOnWaveNormal, 400, 400, FLinearColor::Blue);
			Debug::DrawDebugLine(JetskiComp.RailPosition.WorldLocation, JetskiComp.RailPosition.WorldLocation + FVector(0,0,1000), FLinearColor::Green, 20); 	
		}
#endif
	}
}
