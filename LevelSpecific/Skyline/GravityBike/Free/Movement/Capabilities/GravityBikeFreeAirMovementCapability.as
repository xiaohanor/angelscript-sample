class UGravityBikeFreeAirMovementCapability : UHazeCapability
{
	default CapabilityTags.Add(CapabilityTags::Movement);
	default CapabilityTags.Add(GravityBikeFree::Tags::GravityBikeFree);
	default CapabilityTags.Add(GravityBikeFree::Tags::GravityBikeFreeMovement);

	default TickGroup = EHazeTickGroup::Movement;
	default TickGroupOrder = 50;

	AGravityBikeFree GravityBike;
	UGravityBikeFreeMovementComponent MoveComp;
	UGravityBikeFreeMovementData Movement;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		GravityBike = Cast<AGravityBikeFree>(Owner);
		MoveComp = UGravityBikeFreeMovementComponent::Get(GravityBike);
		Movement = MoveComp.SetupMovementData(UGravityBikeFreeMovementData);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if(MoveComp.HasMovedThisFrame())
			return false;

		if(!MoveComp.IsInAir())
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if(MoveComp.HasGroundContact())
			return true;

		if(!MoveComp.IsInAir())
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		MoveComp.OverrideGravityDirection(FMovementGravityDirection::TowardsDirection(FVector::DownVector), this);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		MoveComp.ClearGravityDirectionOverride(this);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if(!MoveComp.PrepareMove(Movement, GravityBike.GetAcceleratedUp()))
			return;

		if(HasControl())
		{
			const float Speed = GravityBike.ActorVelocity.Size();
			const FQuat DeltaRotation = FQuat(GravityBike.ActorUpVector, GravityBike.GetSteeringAngleRad(Speed) * DeltaTime);
			FVector NewForward = DeltaRotation * GravityBike.ActorForwardVector;

			TickRotation(DeltaTime);
			FQuat NewRotation = FQuat::MakeFromZX(GravityBike.GetAcceleratedUp(), NewForward);

			Movement.SetRotation(NewRotation);

			FVector Velocity = MoveComp.Velocity;
			RotateVelocityTowardsForwardDirection(Velocity, NewRotation.ForwardVector, DeltaTime);

			FVector HorizontalVelocity = Velocity.VectorPlaneProject(FVector::UpVector);
			const float TargetSpeed = Math::Lerp(GravityBike.Settings.AirMinSpeed, GravityBike.Settings.AirMaxSpeed, GravityBike.Input.Throttle);
			if(HorizontalVelocity.Size() > TargetSpeed)
			{
				const FVector VerticalVelocity = Velocity - HorizontalVelocity;
				const FVector TargetHorizontalVelocity = HorizontalVelocity.GetSafeNormal() * TargetSpeed;
				HorizontalVelocity = Math::VInterpTo(HorizontalVelocity, TargetHorizontalVelocity, GravityBike.Settings.AirDeceleration, DeltaTime);
				Velocity = HorizontalVelocity + VerticalVelocity;
			}

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

	void TickRotation(float DeltaTime)
	{
		FVector VerticalVelocity = GravityBike.ActorVelocity.ProjectOnToNormal(MoveComp.WorldUp);
		const FVector HorizontalVelocity = GravityBike.ActorVelocity - VerticalVelocity;

		if(VerticalVelocity.DotProduct(MoveComp.WorldUp) < 0)
			VerticalVelocity *= 0.5;

		const FVector Velocity = (HorizontalVelocity + VerticalVelocity);
		FVector VelocityForward = Velocity.GetSafeNormal();

		if(Velocity.VectorPlaneProject(MoveComp.WorldUp).Size() < 100)
			VelocityForward = GravityBike.ActorForwardVector;

		const FVector VelocityRight = MoveComp.WorldUp.CrossProduct(VelocityForward).GetSafeNormal();

		FVector VelocityUp = VelocityForward.CrossProduct(VelocityRight).GetSafeNormal();

		FRotator TargetRotation = FRotator::MakeFromZX(VelocityUp, VelocityForward);
		TargetRotation.Pitch = Math::Clamp(TargetRotation.Pitch, -60, 60);
		TargetRotation.Normalize();
	}
}