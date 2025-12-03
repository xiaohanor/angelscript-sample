class UGravityBikeFreeKartDriftAirCapability : UHazeCapability
{
	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;
	
	default CapabilityTags.Add(CapabilityTags::Movement);
	default CapabilityTags.Add(GravityBikeFree::Tags::GravityBikeFreeDrift);

	default TickGroup = EHazeTickGroup::Movement;
	default TickGroupOrder = 20;

	AGravityBikeFree GravityBike;
	UGravityBikeFreeKartDriftComponent DriftComp;

	UGravityBikeFreeMovementComponent MoveComp;
	UGravityBikeFreeMovementData Movement;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		GravityBike = Cast<AGravityBikeFree>(Owner);
		DriftComp = UGravityBikeFreeKartDriftComponent::Get(GravityBike);

		MoveComp = UGravityBikeFreeMovementComponent::Get(GravityBike);
		Movement = MoveComp.SetupMovementData(UGravityBikeFreeMovementData);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if(!DriftComp.IsDrifting())
			return false;

		if(MoveComp.HasMovedThisFrame())
			return false;

		if(!GravityBike.MoveComp.IsInAir())
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if(!DriftComp.IsDrifting())
			return true;

		if(MoveComp.HasMovedThisFrame())
			return true;

		if(!GravityBike.MoveComp.IsInAir())
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if(MoveComp.HasMovedThisFrame())
			return;

		if(!MoveComp.PrepareMove(Movement, GravityBike.GetAcceleratedUp()))
			return;

		if(HasControl())
		{
			GravityBike.AddBoost(Movement);

			const float SteeringAngle = DriftComp.GetDriftSteeringAngle(
				DriftComp.Settings.GroundTurnMinAmount,
				DriftComp.Settings.GroundTurnDefaultAmount,
				DriftComp.Settings.GroundTurnMaxAmount
			);

			const FQuat DeltaRotation = FQuat(GravityBike.ActorUpVector, SteeringAngle * DeltaTime);
			FVector NewForward = DeltaRotation * GravityBike.ActorForwardVector;
			FQuat NewRotation = FQuat::MakeFromZX(GravityBike.GetAcceleratedUp(), NewForward);

			Movement.SetRotation(NewRotation);

			FVector Velocity = MoveComp.Velocity;
			RotateVelocityTowardsForwardDirection(Velocity, NewRotation.ForwardVector, DeltaTime);

			const FVector TargetVelocity = Velocity.GetSafeNormal() * GravityBike.Settings.AirMinSpeed;
			Velocity = Math::VInterpConstantTo(Velocity, TargetVelocity, GravityBike.Settings.AirDeceleration, DeltaTime);

			Movement.AddVelocity(Velocity);

			Movement.AddGravityAcceleration();
			Movement.AddPendingImpulses();
			Movement.ApplyMaximumSpeed(GravityBike.Settings.MaxSpeedLimit);
		}
		else
		{
			Movement.ApplyCrumbSyncedAirMovement();
		}

		MoveComp.ApplyMove(Movement);
	}

	void RotateVelocityTowardsForwardDirection(FVector& Velocity, FVector NewForward, float DeltaTime)
	{
		FVector HorizontalVelocity = Velocity.VectorPlaneProject(FVector::UpVector);
		const FVector VerticalVelocity = Velocity - HorizontalVelocity;

		// Interp the velocity along the horizontal plane
		FQuat VelocityRotation = FQuat::MakeFromZX(FVector::UpVector, HorizontalVelocity);
		FQuat NewVelocityRotation = FQuat::MakeFromZX(FVector::UpVector, NewForward);
		VelocityRotation = Math::QInterpTo(VelocityRotation, NewVelocityRotation, DeltaTime, GravityBike.Settings.AirRedirectVelocityAmount);
		HorizontalVelocity = VelocityRotation.ForwardVector * HorizontalVelocity.Size();

		Velocity = HorizontalVelocity + VerticalVelocity;
	}
};