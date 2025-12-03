
class UCoastBomblingMovementCapability : UBasicAIMovementCapability
{	
	default CapabilityTags.Add(n"GroundMovement");	

	UGroundPathfollowingSettings GroundPathfollowingSettings;
	USteppingMovementData SteppingMovement;

	ACoastTrainCart TrainCart;
	FTransform PreviousTrainCartTransform;
	FVector BaseVelocity;
	FSplinePosition RailPosition;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Super::Setup();
		GroundPathfollowingSettings = UGroundPathfollowingSettings::GetSettings(Owner);
		SteppingMovement = Cast<USteppingMovementData>(Movement);
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		Super::OnActivated();
		
		auto RespawnComp = UHazeActorRespawnableComponent::Get(Owner);
		if (RespawnComp != nullptr && RespawnComp.Spawner != nullptr && RespawnComp.Spawner.AttachParentActor != nullptr)
			TrainCart = Cast<ACoastTrainCart>(RespawnComp.Spawner.AttachParentActor);
		else if (Owner.AttachParentActor != nullptr)
			TrainCart = Cast<ACoastTrainCart>(Owner.AttachParentActor);
		else
			TrainCart = nullptr;

		if(TrainCart != nullptr)
		{
			PreviousTrainCartTransform = TrainCart.ActorTransform;
			RailPosition = TrainCart.Driver.RailSpline.GetClosestSplinePositionToWorldLocation(Owner.ActorLocation);
			MoveComp.ApplyFollowEnabledOverride(this, EMovementFollowEnabledStatus::FollowEnabled);
			MoveComp.FollowComponentMovement(TrainCart.RootComponent, this, Priority = EInstigatePriority::Normal);
		}
		else
		{
			PreviousTrainCartTransform = FTransform::Identity;
			RailPosition = FSplinePosition();
		}

		if (Owner.AttachParentActor != nullptr)
		 	Owner.DetachFromActor();

		BaseVelocity = FVector::ZeroVector;
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		MoveComp.UnFollowComponentMovement(this);
		MoveComp.ClearFollowEnabledOverride(this);
	}

	UBaseMovementData SetupMovementData() override
	{
		return MoveComp.SetupSteppingMovementData();
	} 

	bool PrepareMove() override
	{
		return MoveComp.PrepareMove(SteppingMovement);
	}

	void ApplyCrumbSyncedMovement(FVector Velocity) override
	{
		Movement.ApplyCrumbSyncedGroundMovementWithCustomVelocity(Velocity);			
	}

	void ComposeMovement(float DeltaTime) override
	{	
		FVector OwnLoc = Owner.ActorLocation;

		// Note that destination is set in previous tick so we need to adjust destination to 
		// corresponding position relative to train cart in current tick.
		FVector Destination = GetCurrentDestination();
		FVector LocalDest = PreviousTrainCartTransform.InverseTransformPosition(Destination);
		FTransform CurrentTransform = TrainCart == nullptr ? FTransform::Identity : TrainCart.ActorTransform;
		Destination = CurrentTransform.TransformPosition(LocalDest);

		FVector HorizontalVelocity = BaseVelocity.ConstrainToPlane(MoveComp.WorldUp);
		FVector VerticalVelocity = BaseVelocity - HorizontalVelocity;
		FVector MoveDir = (Destination - OwnLoc).ConstrainToPlane(MoveComp.WorldUp).GetSafeNormal();
		float Friction = MoveComp.IsInAir() ? MoveSettings.AirFriction : MoveSettings.GroundFriction;
		float IntegratedFriction = Math::Exp(-Friction);
		float IntegratedAirFriction = Math::Exp(-MoveSettings.AirFriction);

		if (DestinationComp.HasDestination() && !OwnLoc.IsWithinDist(Destination, PathingSettings.AtDestinationRange)) 
		{
			// Move towards destination at given speed, ignore friction (might want to accelerate speed though)
			float MoveSpeed = DestinationComp.Speed;
			HorizontalVelocity = MoveDir * MoveSpeed;
		}
		else
		{
			// Slow to a stop
			DestinationComp.ReportStopping();
			HorizontalVelocity *= Math::Pow(IntegratedFriction, DeltaTime); 
		}

		// Fall
		VerticalVelocity += FVector::UpVector * -982.0 * DeltaTime;
		VerticalVelocity *= Math::Pow(IntegratedAirFriction, DeltaTime); 

		// Recombine and apply velocity
		BaseVelocity = HorizontalVelocity + VerticalVelocity;
		Movement.AddVelocity(BaseVelocity);

		CustomVelocity += DestinationComp.CustomAcceleration * DeltaTime;
		CustomVelocity *= Math::Pow(IntegratedFriction, DeltaTime);
		Movement.AddVelocity(CustomVelocity);

		// Turn towards focus?
		if (DestinationComp.Focus.IsValid())
			MoveComp.RotateTowardsDirection(DestinationComp.Focus.GetFocusLocation() - Owner.FocusLocation, MoveSettings.TurnDuration, DeltaTime, Movement);
		// Turn towards destination if still some ways off
		else if (DestinationComp.HasDestination() && !OwnLoc.IsWithinDist(Destination, PathingSettings.AtDestinationRange))
			MoveComp.RotateTowardsDirection(MoveDir, MoveSettings.TurnDuration, DeltaTime, Movement);
		// Slow to a stop
		else  
			MoveComp.StopRotating(MoveSettings.StopTurningDamping, DeltaTime, Movement);

		Movement.AddPendingImpulses();

		PreviousTrainCartTransform = CurrentTransform;
	}
}
