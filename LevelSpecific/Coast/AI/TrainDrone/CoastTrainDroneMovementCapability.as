
class UCoastTrainDroneMovementCapability : UBasicAIMovementCapability
{	
	default CapabilityTags.Add(n"FlyingMovement");	

	ACoastTrainCart TrainCart;
	FSplinePosition RailPosition;
	UCoastTrainDroneSettings DroneSettings;	
	FVector BaseVelocity;
	float WobbleTimer;
	FHazeAcceleratedFloat FollowRailSpeed;
	USimpleMovementData SlidingMovement;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Super::Setup();
		
		DroneSettings = UCoastTrainDroneSettings::GetSettings(Owner);
		WobbleTimer = Math::RandRange(0.0, 5.0);
		SlidingMovement = Cast<USimpleMovementData>(Movement);
	}

	UBaseMovementData SetupMovementData() override
	{
		return MoveComp.SetupSimpleMovementData();
	} 

	bool PrepareMove() override
	{
		return MoveComp.PrepareMove(SlidingMovement);
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		Super::OnActivated();

		BaseVelocity = FVector::ZeroVector;

		UHazeSplineComponent Rail = GetTrainRailSpline();
		if (ensure(Rail != nullptr))
		{
			float DistAlongRail = Rail.GetClosestSplineDistanceToWorldLocation(Owner.ActorLocation);		
			RailPosition = FSplinePosition(Rail, DistAlongRail, true);
		}
		FollowRailSpeed.SnapTo(GetFollowRailTargetSpeed());

		if (Owner.AttachParentActor == TrainCart)
			Owner.DetachFromActor(EDetachmentRule::KeepWorld, EDetachmentRule::KeepWorld, EDetachmentRule::KeepWorld);
	}

	UHazeSplineComponent GetTrainRailSpline()
	{
		// Find the train rail we should move along
		auto RespawnComp = UHazeActorRespawnableComponent::Get(Owner);
		if (RespawnComp != nullptr && RespawnComp.Spawner != nullptr && RespawnComp.Spawner.AttachParentActor != nullptr)
			TrainCart = Cast<ACoastTrainCart>(RespawnComp.Spawner.AttachParentActor);
		else if (Owner.AttachParentActor != nullptr)
			TrainCart = Cast<ACoastTrainCart>(Owner.AttachParentActor);
		else
			TrainCart = nullptr;

		// Entrance spline?
		if (RespawnComp.SpawnParameters.Spline != nullptr)
			return RespawnComp.SpawnParameters.Spline;

		// Enrance scenepoint with spline?
		UHazeSplineComponent ScenepointSpline = (RespawnComp.SpawnParameters.Scenepoint != nullptr) ? UHazeSplineComponent::Get(RespawnComp.SpawnParameters.Scenepoint.Owner) : nullptr;
		if (ScenepointSpline != nullptr)
			return ScenepointSpline;	

		// Is spawner attached to a train cart?
		if (TrainCart != nullptr)
			return TrainCart.RailSpline;

		// No rail 
 		check(false);
		return nullptr;
	}

	void ComposeMovement(float DeltaTime) override
	{	
		FVector OwnLoc = Owner.ActorLocation;
		FVector Destination = DestinationComp.Destination;
		FVector MoveDir = (Destination - OwnLoc).GetSafeNormal();
		
		if (DestinationComp.Speed > 0.0)
		{
			// Accelerate towards destination
			BaseVelocity += MoveDir * DestinationComp.Speed * DeltaTime;				
		}
		else
		{
			// No destination, let friction slow us to a stop 
			Destination = OwnLoc;
			DestinationComp.ReportStopping();
		}

		// Apply friction
		BaseVelocity -= BaseVelocity * MoveSettings.AirFriction * DeltaTime;
		Movement.AddVelocity(BaseVelocity);

		// Custom acceleration
		CustomVelocity += DestinationComp.CustomAcceleration * DeltaTime;
		CustomVelocity -= CustomVelocity * MoveSettings.AirFriction * DeltaTime;
		Movement.AddVelocity(CustomVelocity);

		// Wobble 
		WobbleTimer += DroneSettings.WobbleFrequency * DeltaTime;
		Movement.AddVelocity(FVector(0.0, 0.0, DroneSettings.WobbleAmplitude * Math::Sin(WobbleTimer)));

		// Keep station with train
		FollowRailSpeed.AccelerateTo(GetFollowRailTargetSpeed(), 1.0, DeltaTime);
		FVector RailOffset = RailPosition.WorldTransform.InverseTransformPosition(OwnLoc);
		RailPosition.Move(FollowRailSpeed.Value * DeltaTime);
		FVector StationKeepingLoc = RailPosition.WorldTransform.TransformPosition(RailOffset); 
		Movement.AddDelta(StationKeepingLoc - OwnLoc);

		// Adjust rail position to match actual position
		RailPosition.Move(Math::Clamp(RailOffset.X, -10000.0, 10000.0) * DeltaTime);

		// Turn towards focus or direction of move
		if (DestinationComp.Focus.IsValid())
			MoveComp.RotateTowardsDirection(DestinationComp.Focus.GetFocusLocation() - Owner.FocusLocation, MoveSettings.TurnDuration, DeltaTime, Movement);
		else if (!OwnLoc.IsWithinDist(Destination, PathingSettings.AtDestinationRange))
			MoveComp.RotateTowardsDirection(MoveDir, MoveSettings.TurnDuration, DeltaTime, Movement);
		else  
			MoveComp.StopRotating(MoveSettings.StopTurningDamping, DeltaTime, Movement);

		Movement.AddPendingImpulses();
	}

	float GetFollowRailTargetSpeed()
	{
		if ((TrainCart != nullptr) && (TrainCart.Driver != nullptr))
		{
			// We just take the driver velocity size, check if that's ok
			return TrainCart.Driver.ActorVelocity.Size();
			// return TrainCart.Driver.GetTrainSpeed();
		}

		if (Game::Players.Num() == 0)
			return 0.0;

		// This is crap when a player dies
		FVector PlayerVelocity = FVector::ZeroVector;
		for (AHazePlayerCharacter Player : Game::Players)
		{
			PlayerVelocity += Player.GetRawLastFrameTranslationVelocity();
		}
		return PlayerVelocity.Size() / Game::Players.Num();
	}
}
