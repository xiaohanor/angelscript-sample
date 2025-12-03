class UDroneMoveAirCapability : UHazePlayerCapability
{
	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;
	default DebugCategory = Drone::DebugCategory;

	default CapabilityTags.Add(CapabilityTags::Movement);
	default CapabilityTags.Add(PrisonTags::Prison);
	default CapabilityTags.Add(PrisonTags::Drones);
	default CapabilityTags.Add(DroneCommonTags::BaseDroneMovement);
	default CapabilityTags.Add(DroneCommonTags::BaseDroneAirMovement);

	default TickGroup = EHazeTickGroup::Movement;
	default TickGroupOrder = 103;

	UDroneComponent DroneComp;
	UHazeMovementComponent MoveComp;
	UDroneMovementData MoveData;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		DroneComp = UDroneComponent::Get(Owner);
		MoveComp = UHazeMovementComponent::Get(Owner);
		MoveData = MoveComp.SetupMovementData(UDroneMovementData);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if(MoveComp.HasMovedThisFrame())
			return false;

		if(MoveComp.IsOnWalkableGround())
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if(MoveComp.HasMovedThisFrame())
			return true;

		if(MoveComp.IsOnWalkableGround())
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(const float Dt)
	{	
		if(!MoveComp.PrepareMove(MoveData))
			return;

		if(HasControl())
		{
			// Make sure that the player is facing the correct direction
			if(!MoveComp.HorizontalVelocity.IsNearlyZero(1.0))
				MoveData.SetRotation(FQuat::MakeFromXZ(MoveComp.Velocity, Player.MovementWorldUp));

			CalculateDeltaMove(Dt);

			if(DroneComp.MovementSettings.bUnstableOnEdges)
				MoveData.ApplyUnstableEdgeDistance(FMovementSettingsValue::MakeValue(0));
		}
		else
		{
			MoveData.ApplyCrumbSyncedAirMovement();
		}

		MoveComp.ApplyMove(MoveData);
	}

	void CalculateDeltaMove(const float DeltaTime) const
	{
		FVector Delta = FVector::ZeroVector;
		FVector Velocity = MoveComp.Velocity;
		FVector MovementInput = MoveComp.MovementInput;

		Drone::TickAirMove(
			Delta,
			Velocity,
			MovementInput,
			DeltaTime,
			DroneComp.MovementSettings.AirMaxHorizontalSpeed,
			DroneComp.MovementSettings.AirMaxSpeedDeceleration,
			DroneComp.MovementSettings.AirReboundMultiplier,
			DroneComp.MovementSettings.AirAcceleration,
			DroneComp.MovementSettings.AirMaxFallSpeed,
			DroneComp.MovementSettings.AirMaxFallDeceleration
		);

		MoveData.AddDeltaWithCustomVelocity(Delta, Velocity);

		// Also add world impulses
		MoveData.AddPendingImpulses();
	}
};

namespace Drone
{
	void TickAirMove(
		FVector& Delta,
		FVector& Velocity,
		FVector MovementInput,
		float DeltaTime,
		float MaxHorizontalSpeed,
		float MaxSpeedDeceleration,
		float ReboundMultiplier,
		float Acceleration,
		float MaxFallSpeed,
		float MaxFallDeceleration)
	{
		Delta += Velocity * DeltaTime;

		FVector VerticalVelocity = Velocity.ProjectOnTo(FVector::UpVector);
		FVector HorizontalVelocity = Velocity - VerticalVelocity;

		// Input
		const bool bIsInputting = !MovementInput.IsNearlyZero();

		if(IsOverHorizontalMaxSpeed(HorizontalVelocity, MaxHorizontalSpeed))
		{
			// Decelerate if over max speed
			HorizontalVelocity = Acceleration::VInterpVelocityConstantToFramerateIndependent(
				HorizontalVelocity,
				HorizontalVelocity.GetClampedToMaxSize(MaxHorizontalSpeed),
				DeltaTime,
				MaxSpeedDeceleration,
				Delta
			);
		}

		if(bIsInputting)
		{
			const bool bIsAccelerating = HorizontalVelocity.DotProduct(MovementInput) > 0;
			const bool bIsRebound = !bIsAccelerating;

			float Multiplier = 1;
			if(bIsRebound)
				Multiplier *= Math::Lerp(1, ReboundMultiplier, MovementInput.Size());

			if(!IsOverHorizontalMaxSpeed(HorizontalVelocity, MaxHorizontalSpeed) || !bIsAccelerating)
			{
				// If we are below max speed, or decelerating, apply movement input
				FVector MoveAcceleration = MovementInput * Acceleration * Multiplier;
				Acceleration::ApplyAccelerationToVelocity(HorizontalVelocity, MoveAcceleration, DeltaTime, Delta);
			}
		}

		// Gravity
		Acceleration::ApplyAccelerationToVelocity(VerticalVelocity, FVector::DownVector * Drone::Gravity, DeltaTime, Delta);

		// Limit falling speed
		if(VerticalVelocity.Z < -Math::Abs(MaxFallSpeed))
		{
			VerticalVelocity = Acceleration::VInterpVelocityConstantToFramerateIndependent(
				VerticalVelocity,
				VerticalVelocity.GetClampedToMaxSize(Math::Abs(MaxFallSpeed)),
				DeltaTime,
				MaxFallDeceleration,
				Delta
			);
		}

		Velocity = HorizontalVelocity + VerticalVelocity;
	}

	bool IsOverHorizontalMaxSpeed(FVector HorizontalVelocity, float MaxHorizontalSpeed)
	{
		return HorizontalVelocity.Size() > MaxHorizontalSpeed;
	}
}