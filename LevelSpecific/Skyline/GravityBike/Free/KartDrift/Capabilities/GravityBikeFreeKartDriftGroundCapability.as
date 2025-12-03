class UGravityBikeFreeKartDriftGroundCapability : UHazeCapability
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

		if(GravityBike.MoveComp.IsInAir())
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

		if(GravityBike.MoveComp.IsInAir())
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		UGravityBikeFreeEventHandler::Trigger_OnDriftStart(GravityBike);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		UGravityBikeFreeEventHandler::Trigger_OnDriftEnd(GravityBike);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if(!MoveComp.PrepareMove(Movement, GravityBike.GetAcceleratedUp()))
			return;

		if(HasControl())
		{
			float ForwardSpeed = MoveComp.GetForwardSpeed(MoveComp.WorldUp);
			MoveComp.AccelerateTowardsTargetSpeed(ForwardSpeed, DeltaTime);

			float SideSpeedDeceleration = GravityBike.Settings.SideSpeedDeceleration * 2;
			// if(ActiveDuration < DriftComp.Settings.GroundDriftSideDragIncreaseTime)
			// {
			// 	float Alpha = ActiveDuration / DriftComp.Settings.GroundDriftSideDragIncreaseTime;
			// 	SideSpeedDeceleration = Math::Lerp(0, SideSpeedDeceleration, Alpha);
			// }

			FVector Velocity = MoveComp.Velocity;
			MoveComp.SetForwardSpeed(Velocity, ForwardSpeed, MoveComp.WorldUp, DeltaTime, SideSpeedDeceleration);
			Movement.AddVelocity(Velocity);

			const float SteeringAngle = DriftComp.GetDriftSteeringAngle(
				DriftComp.Settings.GroundTurnMinAmount,
				DriftComp.Settings.GroundTurnDefaultAmount,
				DriftComp.Settings.GroundTurnMaxAmount
			);
			
			const FQuat DeltaRotation = FQuat(GravityBike.GetAcceleratedUp(), SteeringAngle * DeltaTime);
			const FVector NewForward = DeltaRotation * GravityBike.ActorForwardVector;
			const FQuat NewRotation = FQuat::MakeFromZX(GravityBike.GetAcceleratedUp(), NewForward);
			Movement.SetRotation(NewRotation);

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
};