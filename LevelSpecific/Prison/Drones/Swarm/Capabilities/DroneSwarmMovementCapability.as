class UDroneSwarmMovementCapability : UHazePlayerCapability
{
	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;

	default CapabilityTags.Add(SwarmDroneTags::SwarmDrone);
	default CapabilityTags.Add(SwarmDroneTags::SwarmMovementCapability);
	default CapabilityTags.Add(CapabilityTags::Movement);

	default TickGroup = EHazeTickGroup::ActionMovement;

	UPlayerSwarmDroneComponent SwarmDroneComponent;
	UPlayerSwarmDroneHijackComponent SwarmDroneHijackComponent;
	UPlayerMovementComponent MovementComponent;
	USteppingMovementData MoveData;

	FVector MoveInput;

	UPrisonSwarmMovementSettings MovementSettings;

	float OGStickTogetherValue;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		SwarmDroneComponent = UPlayerSwarmDroneComponent::Get(Owner);
		SwarmDroneHijackComponent = UPlayerSwarmDroneHijackComponent::Get(Owner);
		MovementComponent = UPlayerMovementComponent::Get(Owner);
		MoveData = MovementComponent.SetupSteppingMovementData();
		MovementSettings = UPrisonSwarmMovementSettings::GetSettings(SwarmDroneComponent.Player);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (MovementComponent.HasMovedThisFrame())
			return false;

		if (!SwarmDroneComponent.bSwarmModeActive)
			return false;

		if (SwarmDroneHijackComponent.IsHijackActive())
			return false;

		if (SwarmDroneComponent.bDeswarmifying)
			return false;

		if (!MovementComponent.IsOnAnyGround())
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (MovementComponent.HasMovedThisFrame())
			return true;

		if (!SwarmDroneComponent.bSwarmModeActive)
			return true;

		if (SwarmDroneHijackComponent.IsHijackActive())
			return true;

		if (SwarmDroneComponent.bDeswarmifying)
			return true;

		if (!MovementComponent.IsOnAnyGround())
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		Player.BlockCapabilities(DroneCommonTags::BaseDroneMovement, this);

		// Inherit previous velocity as input and scale it
		MoveInput = MovementComponent.Velocity.GetSafeNormal() * (MovementComponent.Velocity.Size() / 900.0);

		UMovementStandardSettings::SetWalkableSlopeAngle(Player, 40.0, this);

		OGStickTogetherValue = UPrisonSwarmMovementSettings::GetSettings(Player).StickTogetherMultiplier;
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		Player.UnblockCapabilities(DroneCommonTags::BaseDroneMovement, this);

		Player.ClearCameraSettingsByInstigator(this);

		UMovementStandardSettings::ClearWalkableSlopeAngle(Player, this);
		UPrisonSwarmMovementSettings::ClearStickTogetherMultiplier(Player, this);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		// Debug::DrawDebugCapsule(Player.ActorLocation + Player.MovementWorldUp * Player.CapsuleComponent.CapsuleRadius, Player.CapsuleComponent.GetCapsuleHalfHeight(), Player.CapsuleComponent.GetCapsuleRadius(), Player.ActorRotation, FLinearColor::DPink, 2.0);
		// Player.DebugDrawCollisionCapsule();

		// Handle rotation
		if (!MovementComponent.Velocity.IsNearlyZero())
			Player.SetMovementFacingDirection(MovementComponent.Velocity.GetSafeNormal());

		if (MovementComponent.PrepareMove(MoveData))
		{
			if (HasControl())
			{
				// Get last frame's velocity
				FVector Velocity = MovementComponent.Velocity;

				// Calculate frame input
				MoveInput = Math::VInterpTo(MoveInput, MovementComponent.MovementInput, DeltaTime, MovementSettings.AccelerationInterpSpeed);

				// Add input velocity
				FVector InputVelocity = MoveInput * SwarmDrone::Movement::Speed;
				Velocity += InputVelocity;

				FVector Gravity = -Player.MovementWorldUp * Drone::Gravity;
				MoveData.AddAcceleration(Gravity);

				// Add friction
				FVector AccDrag = -MovementComponent.Velocity;
				AccDrag *= MovementComponent.IsOnAnyGround() ? SwarmDrone::Movement::DragGrounded : SwarmDrone::Movement::DragAirborne;
				AccDrag = AccDrag.GetClampedToMaxSize(MovementComponent.Velocity.Size());
				AccDrag = AccDrag.VectorPlaneProject(Player.MovementWorldUp);
				Velocity += AccDrag;

				Player.GetMeshOffsetComponent().ClearOffset(this);

				MoveData.InterpRotationToTargetFacingRotation(SwarmDrone::Movement::RotationSpeed);

				Velocity = Velocity.GetClampedToMaxSize(SwarmDroneComponent.MovementSettings.GroundMaxHorizontalSpeed);

				MoveData.AddVelocity(Velocity);
			}
			else
			{
				MoveData.ApplyCrumbSyncedGroundMovement();
			}

			MovementComponent.ApplyMove(MoveData);
		}

		// Bring swarm closer as time goes by
		float Alpha = Math::Square(Math::Saturate(ActiveDuration / 1.2));
		float StickTogetherMultiplierValue = Math::Lerp(OGStickTogetherValue, SwarmDrone::Movement::SwarmStickTogetherGroundMultiplier, Alpha);
		UPrisonSwarmMovementSettings::SetStickTogetherMultiplier(Player, StickTogetherMultiplierValue, this);
	}

	// Grossly update camera pivot offset, temporary
	void UpdateCameraPosition()
	{
		// FVector AverageLocation;
		// for (auto SwarmBot : SwarmDroneComponent.SwarmBots)
		// 	AverageLocation += SwarmBot.WorldLocation;

		// AverageLocation /= SwarmDroneComponent.SwarmSize;

		// FVector CameraOffset = (AverageLocation - Player.ActorLocation).ConstrainToPlane(MovementComponent.WorldUp) + MovementComponent.WorldUp * 100.0;
		// Player.ApplyPivotOffset(CameraOffset, 1, this);
	}
}