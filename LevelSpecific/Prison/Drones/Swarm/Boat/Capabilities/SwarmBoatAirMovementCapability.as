class USwarmBoatAirMovementCapability : UHazePlayerCapability
{
	default CapabilityTags.Add(CapabilityTags::Movement);
	default CapabilityTags.Add(PrisonTags::Prison);
	default CapabilityTags.Add(PrisonTags::Drones);
	default CapabilityTags.Add(SwarmDroneTags::SwarmDrone);
	default CapabilityTags.Add(SwarmDroneTags::BoatAirMovementCapability);

	default TickGroup = EHazeTickGroup::ActionMovement;
	default TickGroupOrder = 96;

	default DebugCategory = Drone::DebugCategory;

	UPlayerSwarmDroneComponent SwarmDroneComponent;
	UPlayerSwarmBoatComponent SwarmBoatComponent;
	UPlayerMovementComponent MovementComponent;
	USimpleMovementData MoveData;

	USwarmBoatSettings Settings;

	FHazeAcceleratedFloat AcceleratedRoll;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		SwarmDroneComponent = UPlayerSwarmDroneComponent::Get(Player);
		SwarmBoatComponent = UPlayerSwarmBoatComponent::Get(Player);
		MovementComponent = UPlayerMovementComponent::Get(Player);
		MoveData = MovementComponent.SetupSimpleMovementData();

		Settings = USwarmBoatSettings::GetSettings(Player);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (!SwarmBoatComponent.IsBoatActive())
			return false;

		if (MovementComponent.HasMovedThisFrame())
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (!SwarmBoatComponent.IsBoatActive())
			return true;

		if (MovementComponent.HasMovedThisFrame())
			return true;
		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		AcceleratedRoll.SnapTo(0);

		Player.ApplyCameraSettings(SwarmBoatComponent.CameraSettings.AirMovementSettings, 2.0, this);

		SpeedEffect::RequestSpeedEffect(Player, 0.2, this, EInstigatePriority::Low);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		Player.ClearCameraSettingsByInstigator(this);

		Player.PlayCameraShake(SwarmBoatComponent.CameraShakes.LandingCameraShakeClass, this);

		SpeedEffect::ClearSpeedEffect(Player, this);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if (MovementComponent.PrepareMove(MoveData))
		{
			if (HasControl())
			{
				FVector HorizontalVelocity = MovementComponent.HorizontalVelocity;

				if (!MovementComponent.MovementInput.IsNearlyZero())
				{
					// float RotationSpeed = MovementComponent.MovementInput.Size() * 80;
					// HorizontalVelocity = HorizontalVelocity.RotateTowards(MovementComponent.MovementInput, RotationSpeed * DeltaTime);
				}

				if (HorizontalVelocity.Size() >= SwarmDroneComponent.MovementSettings.AirMaxHorizontalSpeed)
					HorizontalVelocity = Math::VInterpConstantTo(HorizontalVelocity, HorizontalVelocity.GetClampedToMaxSize(SwarmDroneComponent.MovementSettings.AirMaxHorizontalSpeed), DeltaTime, SwarmDroneComponent.MovementSettings.AirMaxSpeedDeceleration);

				// Add gravity
				FVector VerticalVelocity = MovementComponent.VerticalVelocity;
				VerticalVelocity += MovementComponent.GravityDirection * Drone::Gravity * DeltaTime;

				// Go go go!
				FVector Velocity = HorizontalVelocity + VerticalVelocity;
				MoveData.AddVelocity(Velocity);

				// if (!Velocity.IsNearlyZero())
				FQuat TargetRotation = FQuat::MakeFromXZ(MovementComponent.Velocity, Player.MovementWorldUp);
				MoveData.SetRotation(TargetRotation);
			}
			else
			{
				MoveData.ApplyCrumbSyncedAirMovement();
			}

			MovementComponent.ApplyMove(MoveData);

			// Now rotate mesh
			TickMeshRotation(DeltaTime);
		}
	}

	void TickMeshRotation(float DeltaTime)
	{
		float SignedInput = -MovementComponent.MovementInput.DotProduct(Player.ActorRightVector);

		// Input roll
		float TargetRoll = SignedInput * Settings.AirMaxRoll;
		AcceleratedRoll.AccelerateTo(TargetRoll, 1.0, DeltaTime);
		FQuat RollQuat = FQuat(Player.ActorForwardVector, Math::DegreesToRadians(AcceleratedRoll.Value));

		// Yaw(n)
		FQuat YawQuat = FQuat::MakeFromX(MovementComponent.Velocity);

		FQuat Rotation = Math::QInterpTo(SwarmDroneComponent.DroneMesh.ComponentQuat, RollQuat * YawQuat, DeltaTime, 1.0);
		SwarmDroneComponent.DroneMesh.SetWorldRotation(Rotation);
	}
}