class UDroneMoveCapability : UHazePlayerCapability
{
	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;
	default DebugCategory = Drone::DebugCategory;

	default CapabilityTags.Add(CapabilityTags::Movement);
	default CapabilityTags.Add(PrisonTags::Prison);
	default CapabilityTags.Add(PrisonTags::Drones);
	default CapabilityTags.Add(DroneCommonTags::BaseDroneMovement);
	default CapabilityTags.Add(DroneCommonTags::BaseDroneGroundMovement);

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

		if(!MoveComp.IsOnWalkableGround())
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if(MoveComp.HasMovedThisFrame())
			return true;

		if(!MoveComp.IsOnWalkableGround())
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

			if(DroneComp.MovementSettings.bUseGroundStickynessWhileGrounded)
				MoveData.UseGroundStickynessThisFrame();
		}
		else
		{
			MoveData.UseGroundStickynessThisFrame();
			MoveData.ApplyCrumbSyncedGroundMovement();
		}

		MoveComp.ApplyMove(MoveData);
	}

	void CalculateDeltaMove(const float DeltaTime) const
	{
		FVector Velocity = MoveComp.Velocity;
		FVector Delta = Velocity * DeltaTime;
		FVector MovementInput = MoveComp.MovementInput;

		FVector VerticalVelocity = Velocity.ProjectOnTo(MoveComp.WorldUp);
		FVector HorizontalVelocity = Velocity - VerticalVelocity;

		// Input
		const bool bIsInputting = !MovementInput.IsNearlyZero();

		const float SlopeAngleDeg = MoveComp.GroundContact.Normal.GetAngleDegreesTo(FVector::UpVector);
		const bool bIsOnSlope = SlopeAngleDeg > DroneComp.MovementSettings.MinSlopeAngle;
		const FVector SlopeDir = DroneComp.GetSlopeDirection();

		if(bIsOnSlope)
		{
			FVector HorizontalVelocityAlongSlope = HorizontalVelocity.ProjectOnToNormal(SlopeDir);
			FVector HorizontalVelocitySideSlope = HorizontalVelocity - HorizontalVelocityAlongSlope;
			const bool bIsMovingUpSlope = HorizontalVelocity.DotProduct(SlopeDir) < 0;

			if(bIsMovingUpSlope)
			{
				if(bIsInputting)
				{
					HorizontalVelocityAlongSlope = Acceleration::VInterpVelocityConstantToFramerateIndependent(HorizontalVelocityAlongSlope, 0, DeltaTime, DroneComp.MovementSettings.UpSlopeWithInputDeceleration, Delta);
					HorizontalVelocitySideSlope = Acceleration::VInterpVelocityConstantToFramerateIndependent(HorizontalVelocitySideSlope, 0, DeltaTime, DroneComp.MovementSettings.UpSlopeSideWithInputDeceleration, Delta);
				}
				else
				{
					HorizontalVelocityAlongSlope = Acceleration::VInterpVelocityConstantToFramerateIndependent(HorizontalVelocityAlongSlope, 0, DeltaTime, DroneComp.MovementSettings.UpSlopeDeceleration, Delta);
					HorizontalVelocitySideSlope = Acceleration::VInterpVelocityConstantToFramerateIndependent(HorizontalVelocitySideSlope, 0, DeltaTime, DroneComp.MovementSettings.UpSlopeSideDeceleration, Delta);
				}
			}
			else
			{
				HorizontalVelocityAlongSlope = Acceleration::VInterpVelocityConstantToFramerateIndependent(HorizontalVelocityAlongSlope, 0, DeltaTime, DroneComp.MovementSettings.DownSlopeDeceleration, Delta);
				HorizontalVelocitySideSlope = Acceleration::VInterpVelocityConstantToFramerateIndependent(HorizontalVelocitySideSlope, 0, DeltaTime, DroneComp.MovementSettings.DownSlopeSideDeceleration, Delta);
			}

			HorizontalVelocity = HorizontalVelocitySideSlope + HorizontalVelocityAlongSlope;
		}
		else
		{
			HorizontalVelocity = Acceleration::VInterpVelocityConstantToFramerateIndependent(HorizontalVelocity, FVector::ZeroVector, DeltaTime, DroneComp.MovementSettings.GroundDeceleration, Delta);
		}

		if(bIsInputting)
		{
			const bool bIsRebound = HorizontalVelocity.DotProduct(MovementInput) < 0;

			float Multiplier = 1;
			if(bIsRebound)
				Multiplier *= Math::Lerp(1, DroneComp.MovementSettings.GroundReboundMultiplier, MovementInput.Size());

			if(bIsOnSlope)
			{
				const bool bIsInputtingUpSlope = SlopeDir.DotProduct(MovementInput) < 0;

				if(bIsInputtingUpSlope)
				{
					float SlopeFactor = Math::Saturate(Math::NormalizeToRange(SlopeAngleDeg, DroneComp.MovementSettings.MinSlopeAngle, DroneComp.MovementSettings.MaxInputSlopeAngle));
					SlopeFactor = Math::Pow(SlopeFactor, DroneComp.MovementSettings.UpSlopeExponent);
					Multiplier *= Math::Lerp(1, DroneComp.MovementSettings.UpSlopeMultiplier, SlopeFactor);
				}
			}

			const FVector Acceleration = MovementInput * DroneComp.MovementSettings.GroundAcceleration * Multiplier;
			Acceleration::ApplyAccelerationToVelocity(HorizontalVelocity, Acceleration, DeltaTime, Delta);

			// If we accelerated past the max, clamp
			if(IsOverHorizontalMaxSpeed(HorizontalVelocity))
				HorizontalVelocity = HorizontalVelocity.GetClampedToMaxSize(DroneComp.MovementSettings.GroundMaxHorizontalSpeed);
		}

		if(IsOverHorizontalMaxSpeed(HorizontalVelocity))
		{
			// Decelerate if over max speed
			HorizontalVelocity = Acceleration::VInterpVelocityConstantToFramerateIndependent(HorizontalVelocity, HorizontalVelocity.GetClampedToMaxSize(DroneComp.MovementSettings.GroundMaxHorizontalSpeed), DeltaTime, DroneComp.MovementSettings.GroundMaxSpeedDeceleration, Delta);
		}

		// Gravity
		Acceleration::ApplyAccelerationToVelocity(VerticalVelocity, FVector::DownVector * Drone::Gravity, DeltaTime, Delta);

		Velocity = HorizontalVelocity + VerticalVelocity;

		if(DroneComp.MovementSettings.bStopIfOnFlatGroundWithNoHorizontalVelocity)
		{
			// Try to mitigate sliding on very slightly sloping surfaces by putting the delta straight into the ground, instead of global down, and remove horizontal delta
			if(MoveComp.IsOnWalkableGround() && !bIsOnSlope && HorizontalVelocity.IsNearlyZero() && !Delta.VectorPlaneProject(FVector::UpVector).IsZero())
			{
				Delta = MoveComp.GroundContact.Normal * Delta.DotProduct(FVector::UpVector);
			}
		}

		MoveData.AddDeltaWithCustomVelocity(Delta, Velocity);

		// Also add world impulses
		MoveData.AddPendingImpulses();
	}

	bool IsOverHorizontalMaxSpeed(FVector HorizontalVelocity) const
	{
		return HorizontalVelocity.Size() > DroneComp.MovementSettings.GroundMaxHorizontalSpeed;
	}
};