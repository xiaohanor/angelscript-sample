struct FMagnetDroneSurfaceMovementDeactivateParams
{
	bool bApplyDetachImpulse = false;
	FVector DetachImpulse = FVector::ZeroVector;
};

class UMagnetDroneSurfaceMovementCapability : UHazePlayerCapability
{
	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;
	default DebugCategory = Drone::DebugCategory;

	default CapabilityTags.Add(CapabilityTags::Movement);
	default CapabilityTags.Add(PrisonTags::Prison);
	default CapabilityTags.Add(PrisonTags::Drones);
	default CapabilityTags.Add(MagnetDroneTags::MagnetDrone);
	default CapabilityTags.Add(MagnetDroneTags::MagnetDroneSurfaceMovement);

	default TickGroup = EHazeTickGroup::Movement;
	default TickGroupOrder = 101;

	UMagnetDroneComponent DroneComp;
	UMagnetDroneAttachedComponent AttachedComp;

	UHazeMovementComponent MoveComp;
	UMagnetDroneAttachedMovementData MoveData;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		DroneComp = UMagnetDroneComponent::Get(Player);
		AttachedComp = UMagnetDroneAttachedComponent::Get(Player);

		MoveComp = UHazeMovementComponent::Get(Player);
		MoveData = MoveComp.SetupMovementData(UMagnetDroneAttachedMovementData);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if(MoveComp.HasMovedThisFrame())
			return false;

		if(!AttachedComp.IsAttachedToSurface())
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate(FMagnetDroneSurfaceMovementDeactivateParams& Params) const
	{
		if(MoveComp.HasMovedThisFrame())
			return true;

		if(!AttachedComp.IsAttachedToSurface())
		{
			const FVector WorldUp = AttachedComp.CalculateWorldUp();
			if(ShouldAddDetachImpulse(WorldUp))
			{
				Params.bApplyDetachImpulse = true;
				Params.DetachImpulse = WorldUp * MagnetDrone::DetachImpulse;
			}

			return true;
		}

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FMagnetDroneSurfaceMovementDeactivateParams Params)
	{
		// Apply a small impulse to prevent sliding down along a wall, because that feels bad
		if(Params.bApplyDetachImpulse)
			Player.AddMovementImpulse(Params.DetachImpulse);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(const float DeltaTime)
	{
		// set new world up for the movement that is gonna be calculated
		const FVector WorldUp = AttachedComp.CalculateWorldUp();
		
		if(!MoveComp.PrepareMove(MoveData, WorldUp))
			return;

		if(HasControl())
		{
			MoveData.UseGroundStickynessThisFrame();

			CalculateDeltaMove(WorldUp, DeltaTime);

			// Make sure that the player is facing the correct direction
			MoveData.InterpRotationTo(DroneComp.CalculateDesiredRotation().Quaternion(), MagnetDrone::RotateSpeed, false);

			MoveData.AddPendingImpulses();
		}
		else
		{
			MoveData.ApplyCrumbSyncedGroundMovement();
		}

		MoveComp.ApplyMove(MoveData);
	}

	void CalculateDeltaMove(FVector WorldUp, float DeltaTime) const
	{
		FVector Velocity = MoveComp.Velocity;
		FVector MovementInput = AttachedComp.GetMagnetMoveInput(GetAttributeVector2D(AttributeVectorNames::MovementRaw), WorldUp);

		FVector VerticalVelocity = Velocity.ProjectOnTo(WorldUp);
		FVector HorizontalVelocity = Velocity - VerticalVelocity;

		// Input
		// World space input
		const bool bIsInputting = !MovementInput.IsNearlyZero();

		if(bIsInputting)
		{
			const bool bIsRebound = HorizontalVelocity.DotProduct(MovementInput) < 0;

			float Acceleration = AttachedComp.Settings.Acceleration;
			if(bIsRebound)
				Acceleration *= Math::Lerp(1, AttachedComp.Settings.ReboundMultiplier, MovementInput.Size());

			FVector Force = MovementInput * Acceleration;

			if(bIsRebound)
			{
				// Just decelerate like normal, aiding in the rebound
				HorizontalVelocity = Math::VInterpConstantTo(HorizontalVelocity, FVector::ZeroVector, DeltaTime, AttachedComp.Settings.Deceleration);
			}
			else
			{
				// Applying full deceleration against the acceleration can feel really bad, because at low input we don't move at all
				// Therefore we limit the deceleration when inputting, not rebounding, and the velocity is low
				const float CurrentSpeedAlpha = Math::Saturate(HorizontalVelocity.Size() / 600);
				const float Deceleration = AttachedComp.Settings.Deceleration * CurrentSpeedAlpha;
				HorizontalVelocity = Math::VInterpConstantTo(HorizontalVelocity, FVector::ZeroVector, DeltaTime, Deceleration);
			}

			HorizontalVelocity += (Force * DeltaTime);

			// If we accelerated past the max, clamp
			if(IsOverHorizontalMaxSpeed(HorizontalVelocity))
				HorizontalVelocity = HorizontalVelocity.GetClampedToMaxSize(DroneComp.MovementSettings.GroundMaxHorizontalSpeed);
		}
		else
		{
			HorizontalVelocity = Math::VInterpConstantTo(HorizontalVelocity, FVector::ZeroVector, DeltaTime, AttachedComp.Settings.Deceleration);
		}

		if(IsOverHorizontalMaxSpeed(HorizontalVelocity))
		{
			// Decelerate if over max speed
			HorizontalVelocity = HorizontalVelocity.GetClampedToMaxSize(AttachedComp.Settings.MaxHorizontalSpeed);
		}

		// Gravity
		VerticalVelocity -= WorldUp * (Drone::Gravity * DeltaTime);

		Velocity = HorizontalVelocity + VerticalVelocity;

		if(AttachedComp.AttachedData.GetSurfaceComp().bForceMoveToHeight)
		{
			float TargetHeight = AttachedComp.AttachedData.GetSurfaceComp().Owner.ActorLocation.Z + AttachedComp.AttachedData.GetSurfaceComp().ForceMoveToHeight;
			float CurrentHeight = Player.ActorLocation.Z;

			// Use AcceleratedFloat to prevent overshooting
			FHazeAcceleratedFloat AccForceMoveToHeight;
			AccForceMoveToHeight.SnapTo(CurrentHeight, MoveComp.Velocity.DotProduct(FVector::UpVector));
			AccForceMoveToHeight.AccelerateTo(TargetHeight, 1.0, DeltaTime);

			// Set .Z directly to have full control
			Velocity.Z = AccForceMoveToHeight.Velocity;
		}

		MoveData.AddVelocity(Velocity);

		// Also add world impulses
		MoveData.AddPendingImpulses();
	}

	bool IsOverHorizontalMaxSpeed(FVector HorizontalVelocity) const
	{
		return HorizontalVelocity.Size() > AttachedComp.Settings.MaxHorizontalSpeed;
	}

	bool ShouldAddDetachImpulse(FVector WorldUp) const
	{
		// Don't jump if we have been force detached
		if(AttachedComp.ForceDetachedFromSocketWithJumpThisOrLastFrame())
			return false;

		// Don't jump up if we were magnetized to a floor
		if(WorldUp.Z > 0.5)
			return false;

		// Don't jump if we detached by jumping
		auto JumpComp = UMagnetDroneJumpComponent::Get(Player);
		if(JumpComp.StartedJumpingThisOrLastFrame())
			return false;

		// Don't jump if we started a jump attract
		auto AttractJumpComp = UMagnetDroneAttractJumpComponent::Get(Player);
		if(AttractJumpComp.StartJumpAttractFrame >= Time::FrameNumber - 1)
			return false;

		return true;
	}
}